/// An example of a decentralized lottery that picks its winner based on randomness generated in the future
/// by the drand randomnes beacon.
///
/// WARNING #1: This example has not been audited and should thus NOT be relied upon as an authoritative guide on
/// using `drand` randomness safely in Move.
///
/// WARNING #2: This code makes a STRONG assumption that the Aptos clock and the drand clock are synchronized.
/// In practice, the Aptos clock could be lagging behind. As an example, even though the current time is Friday, July
/// 14th, 2023, 7:34PM, from the perspective of the blockchain validators, the time could be Thursday, July 13th, 2023.
/// (Exaggerating the difference, to make the point clearer.) Therefore, a drand round for noon at Friday would be
/// incorrectly treated as a valid future drand round, even though that round has passed. It is therefore important that
/// contracts account for any drift between the Aptos clock and the drand clock. In this example, this can be done by
/// increasing the MINIMUM_LOTTERY_DURATION_SECS to account for this drift.-

module drand::lottery {
    use std::signer;
    use aptos_framework::account;
    use std::vector;
    use std::option::{Self, Option};
    use aptos_framework::coin;
    use std::error;
    use aptos_framework::timestamp;
    use aptos_framework::aptos_coin::{Self, AptosCoin};
   // use aptos_framework::aptos_coin::AptosCoin;
    use drand::drand;
    //use aptos_std::debug;

    /// Error code code when someone tries to start a very "short" lottery where users might not have enough time
    /// to buy tickets.
    const E_LOTTERY_IS_NOT_LONG_ENOUGH: u64 = 0;
    /// Error code for when someone tries to modify the time when the lottery is drawn.
    /// Once set, this time cannot be modified (for simplicity).
    const E_LOTTERY_ALREADY_STARTED: u64 = 1;
    /// Error code for when a user tries to purchase a ticket after the lottery has closed. This would not be secure
    /// since such users might know the public randomness, which is revealed soon after the lottery has closed.
    const E_LOTTERY_HAS_CLOSED: u64 = 2;
    /// Error code for when a user tries to initiating the drawing too early (enough time must've elapsed since the
    /// lottery started for users to have time to register).
    const E_LOTTERY_DRAW_IS_TOO_EARLY: u64 = 3;
    /// Error code for when anyone submits an incorrect randomness for the randomized draw phase of the lottery.
    const E_INCORRECT_RANDOMNESS: u64 = 4;

    /// The minimum time between when a lottery is 'started' and when it's closed & the randomized drawing can happen.
    /// Currently set to (10 mins * 60 secs / min) seconds.
    const MINIMUM_LOTTERY_DURATION_SECS: u64 = 10 * 60;

    /// The minimum price of a lottery ticket.
    const TICKET_PRICE: u64 = 10000;

    /// A lottery: a list of users who bought tickets and a time past which the randomized drawing can happen.
    ///
    /// The winning user will be randomly picked (via drand public randomness) from this list.
    struct Lottery has key {
        // A list of which users bought lottery tickets
        tickets: vector<address>,

        // The time when the lottery ends (and thus when the drawing happens).
        // Specifically, the drawing will happen during the drand round at time `draw_at`.
        // `None` if the lottery is in the 'not started' state.
        draw_at: Option<u64>,

        // Signer for the resource accounts storing the coins that can be won
        signer_cap: account::SignerCapability,
    }

    // Declare the testing module as a friend, so it can call `init_module` below for testing.
    // friend drand::lottery_test;

    /// Initializes a so-called "resource" account which will maintain the list of lottery tickets bought by users.
    fun init_module(deployer: &signer) {
        // Create the resource account. This will allow this module to later obtain a `signer` for this account and
        // update the list of purchased lottery tickets.
        let (_resource, signer_cap) = account::create_resource_account(deployer, vector::empty());

        // Acquire a signer for the resource account that stores the coin bounty
        let rsrc_acc_signer = account::create_signer_with_capability(&signer_cap);

        // Initialize an AptosCoin coin store there, which is where the lottery bounty will be kept
        coin::register<AptosCoin>(&rsrc_acc_signer);

        // Initialiaze the loterry as 'not started'
        move_to(deployer,
            Lottery {
                tickets: vector::empty<address>(),
                draw_at: option::none(),
                signer_cap,
            }
        )
    }

    public fun get_ticket_price(): u64 { TICKET_PRICE }
    public fun get_minimum_lottery_duration_in_secs(): u64 { MINIMUM_LOTTERY_DURATION_SECS }

    /// Allows anyone to start & configure the lottery so that drawing happens at time `draw_at` (and thus users
    /// have plenty of time to buy tickets), where `draw_at` is a UNIX timestamp in seconds.
    ///
    /// NOTE: A real application can access control this.
    public entry fun start_lottery(end_time_secs: u64) acquires Lottery {
        // Make sure the lottery stays open long enough for people to buy tickets.
        assert!(end_time_secs >= timestamp::now_seconds() + MINIMUM_LOTTERY_DURATION_SECS, error::out_of_range(E_LOTTERY_IS_NOT_LONG_ENOUGH));

        // Update the Lottery resource with the (future) lottery drawing time, effectively 'starting' the lottery.
        let lottery = borrow_global_mut<Lottery>(@drand); // Need move_to the @drand firstly?
        assert!(option::is_none(&lottery.draw_at), error::permission_denied(E_LOTTERY_ALREADY_STARTED));
        lottery.draw_at = option::some(end_time_secs);

        //debug::print(&string::utf8(b"Started a lottery that will draw at time: "));
        //debug::print(&draw_at_in_secs);
    }

    /// Called by any user to purchase a ticket in the lottery.
    public entry fun buy_a_ticket(user: &signer) acquires Lottery {
        // Get the Lottery resource
        let lottery = borrow_global_mut<Lottery>(@drand);

        // Make sure the lottery has been 'started' but has NOT been 'drawn' yet
        let draw_at = *option::borrow(&lottery.draw_at);
        assert!(timestamp::now_seconds() < draw_at, error::out_of_range(E_LOTTERY_HAS_CLOSED));

        // Get the address of the resource account that stores the coin bounty
        let (_, rsrc_acc_addr) = get_rsrc_acc(lottery);

        // Charge the price of a lottery ticket from the user's balance, and accumulate it into the lottery's bounty
        coin::transfer<AptosCoin>(user, rsrc_acc_addr, TICKET_PRICE);

        // ...and issue a ticket for that user
        vector::push_back(&mut lottery.tickets, signer::address_of(user))
    }

    /// Allows anyone to close the lottery (if enough time has elapsed) and to decide the winner, by uploading
    /// the correct _drand-signed bytes_ associated with the committed draw time in `draw_at`.
    /// These bytes will then be verified and used to extract randomness.
    public  fun close_lottery(drand_signed_bytes: vector<u8>): Option<address> acquires Lottery {
        // Get the Lottery resource
        let lottery = borrow_global_mut<Lottery>(@drand);

        // Make sure the lottery has been 'started' and enough time has elapsed before the drawing can start
        let draw_at = *option::borrow(&lottery.draw_at);
        assert!(timestamp::now_seconds() >= draw_at, error::out_of_range(E_LOTTERY_DRAW_IS_TOO_EARLY));

        // It could be that no one signed up...
        if(vector::is_empty(&lottery.tickets)) {
            // It's time to draw, but nobody signed up => nobody won.
            // Close the lottery (even if the randomness might be incorrect).
            option::extract(&mut lottery.draw_at);
            return option::none<address>()
        };

        // Determine the next drand round after `draw_at`
        let drand_round = drand::next_round_after(draw_at);
        debug::print(&drand_round);
        // Verify the randomness for this round and pick a winner
        let randomness = drand::verify_and_extract_randomness(
            drand_signed_bytes,
            drand_round
        );
        assert!(option::is_some(&randomness), error::permission_denied(E_INCORRECT_RANDOMNESS));
        debug::print(&randomness);
        // Close the lottery
        // Use the bytes to pick a number at random from 0 to `|lottery.tickets| - 1` and select the winner
        let winner_idx = drand::random_number(
            option::extract(&mut randomness),
            vector::length(&lottery.tickets)
        );
        debug::print(&winner_idx);

        // Pay the winner
        let (rsrc_acc_signer, rsrc_acc_addr) = get_rsrc_acc(lottery);
        let balance = coin::balance<AptosCoin>(rsrc_acc_addr);
        let winner_addr = *vector::borrow(&lottery.tickets, winner_idx);

        coin::transfer<AptosCoin>(
            &rsrc_acc_signer,
            winner_addr,
            balance);

        option::extract(&mut lottery.draw_at);
        lottery.tickets = vector::empty<address>();
        option::some(winner_addr)
    }

    //
    // Internal functions
    //

    fun get_rsrc_acc(lottery: &Lottery): (signer, address) {
        let rsrc_acc_signer = account::create_signer_with_capability(&lottery.signer_cap);
        let rsrc_acc_addr = signer::address_of(&rsrc_acc_signer);

        (rsrc_acc_signer, rsrc_acc_addr)
    }

    use aptos_std::debug;
    use std::string;
    use aptos_framework::coin::MintCapability;
    #[test_only]
    use aptos_std::crypto_algebra::enable_cryptography_algebra_natives;

#[test_only]
    fun give_coins(mint_cap: &MintCapability<AptosCoin>, to: &signer) {
        let to_addr = signer::address_of(to);
        if (!account::exists_at(to_addr)) {
            account::create_account_for_test(to_addr);
        };
        coin::register<AptosCoin>(to);

        let coins = coin::mint(get_ticket_price(), mint_cap);
        coin::deposit(to_addr, coins);
    }

    #[test(myself = @drand, fx = @aptos_framework, u1 = @0xA001, u2 = @0xA002, u3 = @0xA003, u4 = @0xA004)]
    fun test_lottery(
        myself: signer, fx: signer,
        u1: signer, u2: signer, u3: signer, u4: signer,
    ) acquires Lottery{
        enable_cryptography_algebra_natives(&fx);
        timestamp::set_time_has_started_for_testing(&fx);

        // Deploy the lottery smart contract
        init_module(&myself);

        // Needed to mint coins out of thin air for testing
        let (burn_cap, mint_cap) = aptos_coin::initialize_for_test(&fx);

        // We simulate different runs of the lottery to demonstrate the uniformity of the outcomes
        let vec_signed_bytes = vector::empty<vector<u8>>();
        // curl https://api3.drand.sh/dbd506d6ef76e5f386f41c651dcb808c5bcbd75471cc4eafa3f4df7ad4e4c493/public/202
        vector::push_back(&mut vec_signed_bytes, x"a438d55a0a3aeff6c6b78ad40c2dfb55dae5154d86eeb8163138f2bf96294f90841e75ad952bf8101630da7bb527da21"); // u1 wins.
        // curl https://api3.drand.sh/dbd506d6ef76e5f386f41c651dcb808c5bcbd75471cc4eafa3f4df7ad4e4c493/public/602
        vector::push_back(&mut vec_signed_bytes, x"b0e64fd43f49f3cf20135e7133112c0ae461e6a7b2961ef474f716648a9ab5b67f606af2980944344de131ab970ccb5d"); // u1 wins.
        // curl https://api3.drand.sh/dbd506d6ef76e5f386f41c651dcb808c5bcbd75471cc4eafa3f4df7ad4e4c493/public/1002
        vector::push_back(&mut vec_signed_bytes, x"8a9b54d4790bcc1e0b8b3e452102bfc091d23ede4b488cb81580f37a52762a283ed8c8dd844f0a112fda3d768ec3f9a2"); // u4 wins.
        // curl https://api3.drand.sh/dbd506d6ef76e5f386f41c651dcb808c5bcbd75471cc4eafa3f4df7ad4e4c493/public/1402
        vector::push_back(&mut vec_signed_bytes, x"8eaca04732b0de0c2a385f0ccaab9504592fcae7ca621bef58302d4ef0bd2ce3dd9c90153688dedd47efdbeb4d9ecde5"); // u3 wins.

        let lottery_start_time_secs = 1677685200; // the time that the 1st drand epoch started
        let lottery_duration = get_minimum_lottery_duration_in_secs();

        // We pop_back, so we reverse the vector to simulate pop_front
        vector::reverse(&mut vec_signed_bytes);

        while(!vector::is_empty(&vec_signed_bytes)) {
            let signed_bytes = vector::pop_back(&mut vec_signed_bytes);

            // Create fake coins for users participating in lottery & initialize aptos_framework
            give_coins(&mint_cap, &u1);
            give_coins(&mint_cap, &u2);
            give_coins(&mint_cap, &u3);
            give_coins(&mint_cap, &u4);

            // Simulates the lottery starting at the current blockchain time
            timestamp::update_global_time_for_test(lottery_start_time_secs * 1000 * 1000);

            test_lottery_with_randomness(
                &u1, &u2, &u3, &u4,
                lottery_start_time_secs, lottery_duration,
                signed_bytes
            );

            // Shift the next lottery's start time a little (otherwise, timestamp::update_global_time_for_test fails
            // when resetting the time back to the past).
            lottery_start_time_secs = lottery_start_time_secs + 2 * lottery_duration;
        };

        // Clean up
        coin::destroy_burn_cap<AptosCoin>(burn_cap);
        coin::destroy_mint_cap<AptosCoin>(mint_cap);
    }

    #[test_only]
    fun test_lottery_with_randomness(
        u1: &signer, u2: &signer, u3: &signer, u4: &signer,
        lottery_start_time_secs: u64,
        lottery_duration: u64,
        drand_signed_bytes: vector<u8>,
    ) acquires Lottery {
        //debug::print(&string::utf8(b"The lottery duration is: "));
        //debug::print(&lottery_duration);
        //debug::print(&string::utf8(b"The time before starting it is: "));
        //debug::print(&timestamp::now_seconds());

        let lottery_draw_at_time = lottery_start_time_secs + lottery_duration;

        //
        // Send a TXN to start the lottery
        //
        start_lottery(lottery_draw_at_time);

        //
        // Each user sends a TXN to buy their ticket
        //
        buy_a_ticket(u1);
        buy_a_ticket(u2);
        buy_a_ticket(u3);
        buy_a_ticket(u4);

        // Advance time far enough so the lottery can be closed
        timestamp::fast_forward_seconds(lottery_duration);
        assert!(timestamp::now_seconds() == lottery_draw_at_time, 1);
        //debug::print(&string::utf8(b"The time before closing is: "));
        //debug::print(&timestamp::now_seconds());

        //
        // Send a TXN with `drand_signed_bytes` to close the lottery and determine the winner
        //
        debug::print(&drand_signed_bytes);
        let winner_addr = option::extract(&mut close_lottery(drand_signed_bytes));

        debug::print(&string::utf8(b"The winner is: "));
        debug::print(&winner_addr)
    }
}
