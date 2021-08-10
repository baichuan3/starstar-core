//address 0x9639665933576B9Ed950214db76DF8Eb {
address 0x9639665933576B9Ed950214db76DF8Eb {

module StarStarToken {
    use 0x1::Signer;
    use 0x1::Token;
    use 0x1::Account;

    /// StarStar token marker.
    struct StarStarToken has copy, drop, store { }

    struct TokenCapability<StarStarToken> has key, store {
        mint: Token::MintCapability<StarStarToken>,
        burn: Token::BurnCapability<StarStarToken>,
    }

    /// precision of token.
    const PRECISION: u8 = 9;

    /// StarStar initialization.
    public fun init(account: &signer) {
        Token::register_token<StarStarToken>(account, PRECISION);
        Account::do_accept_token<StarStarToken>(account);

        let mint_capability = Token::remove_mint_capability<StarStarToken>(account);
        let burn_capability = Token::remove_burn_capability<StarStarToken>(account);
        move_to(account, TokenCapability { mint: mint_capability, burn: burn_capability });
    }

    public fun mint(account: &signer, amount: u128) acquires TokenCapability {
        let mint_cap = borrow_global<TokenCapability<StarStarToken>>(admin_address());
        let mint_token = Token::mint_with_capability(&mint_cap.mint, amount);
        if (!Account::is_accepts_token<StarStarToken>(Signer::address_of(account))) {
            Account::do_accept_token<StarStarToken>(account);
        };
        Account::deposit(Signer::address_of(account), mint_token);
    }

    fun admin_address(): address {
        @0x9639665933576B9Ed950214db76DF8Eb
    }
}




module StarStar {
    use 0x1::Collection2;
    use 0x1::Signer;
    use 0x1::Vector;
    use 0x1::Timestamp;

    struct StarInfo<CategoryT: copy+store+drop> has key,store,drop {
        ///star info address
        item_address: address,
        ///every address stared counter
        counter: u64,
        /// Update timestamp millisecond
        updated_at: u64,
    }

    struct CategoryAccountCounter<CategoryT: copy+store+drop> has key,store {
        /// evevy address can only star a category once
        counter: u64
    }



    const ERROR_REGISTER_ADDRESS: u64 = 2001;
    const ERROR_ACCOUNT_ALREADY_STAR_CATEGORY: u64 = 2011;

    /// must by initialization by admin
    public fun init<CategoryT: store+copy+drop>(account: &signer) {
        let owenr_address = Signer::address_of(account);
        if (!Collection2::exists_at<StarInfo<CategoryT>>(owenr_address)) {
            Collection2::create_collection<StarInfo<CategoryT>>(account, false, false);
        };
    }

    /// must by register by admin
    public fun register_item<CategoryT: store+copy+drop>(account: &signer, item_address: address) {
        let owenr_address = Signer::address_of(account);
        assert(owenr_address == admin_address(), ERROR_REGISTER_ADDRESS);
        let now_timestamp = Timestamp::now_milliseconds();
        let item = StarInfo<CategoryT> {
            item_address: item_address,
            counter: 0,
            updated_at: now_timestamp,
        };
        Collection2::put(account, owenr_address, item);
    }

    public fun can_star<CategoryT: copy+store+drop>(sign_address: address) : bool acquires CategoryAccountCounter {
        if (exists<CategoryAccountCounter<CategoryT>>(sign_address)) {
            let category_account_counter = borrow_global_mut<CategoryAccountCounter<CategoryT>>(sign_address);
            if (category_account_counter.counter > 0){
                return false
            };
        };
        true
    }

    public fun star<CategoryT: copy+store+drop>(account: &signer, item_address: address) : bool acquires CategoryAccountCounter {
        let sign_address = Signer::address_of(account);
        assert(can_star<CategoryT>(sign_address), ERROR_ACCOUNT_ALREADY_STAR_CATEGORY);

        // catogery account counter + 1
        if (! exists<CategoryAccountCounter<CategoryT>>(sign_address)) {
            let category_account_counter = CategoryAccountCounter<CategoryT> {
                counter: 0,
            };
            move_to(account, category_account_counter);
        };
        let category_account_counter = borrow_global_mut<CategoryAccountCounter<CategoryT>>(sign_address);
        category_account_counter.counter = category_account_counter.counter + 1;


        // cotegory item counter +1
        let items = Collection2::borrow_collection<StarInfo<CategoryT>>(account, admin_address());
        let i = 0;
        let len = Collection2::length(&items);
        while (i < len) {
            let mut_item = Collection2::borrow_mut(&mut items, i);
            if (mut_item.item_address == item_address) {
                mut_item.counter = mut_item.counter + 1;
                mut_item.updated_at = Timestamp::now_milliseconds();
                break
            };
            i = i + 1;
        };
        Collection2::return_collection(items);
        true
    }

    public fun unstar<CategoryT: copy+store+drop>(account: &signer, item_address: address) : bool acquires CategoryAccountCounter {
        let sign_address = Signer::address_of(account);

        // catogery account counter - 1
        if (exists<CategoryAccountCounter<CategoryT>>(sign_address)) {
            let category_account_counter = borrow_global_mut<CategoryAccountCounter<CategoryT>>(sign_address);
            if (category_account_counter.counter > 0){
                category_account_counter.counter = category_account_counter.counter - 1;
            }
        };

        // cotegory item counter - 1
        let items = Collection2::borrow_collection<StarInfo<CategoryT>>(account, admin_address());
        let i = 0;
        let len = Collection2::length(&items);
        while (i < len) {
            let mut_item = Collection2::borrow_mut(&mut items, i);
            if (mut_item.item_address == item_address) {
                mut_item.counter = mut_item.counter - 1;
                mut_item.updated_at = Timestamp::now_milliseconds();
                break
            };
            i = i + 1;
        };
        Collection2::return_collection(items);
        true
    }


    public fun get_topn_list<CategoryT: copy+store+drop>(account: &signer): vector<StarInfo<CategoryT>> {
        let items = Collection2::borrow_collection<StarInfo<CategoryT>>(account, Signer::address_of(account));
        let topn_list = Vector::empty();
        let i = 0;
        let len = Collection2::length(&items);
        while (i < len) {
            let item = Collection2::borrow(&items, i);
            let topn_item = StarInfo<CategoryT> {
                item_address: item.item_address,
                counter: item.counter,
                updated_at: item.updated_at,
            };

            Vector::push_back(&mut topn_list, topn_item);
            i = i + 1;
        };
        Collection2::return_collection(items);
        return topn_list
    }

    fun admin_address(): address {
        @0x9639665933576B9Ed950214db76DF8Eb
    }
}


module TokenCategory{
    use 0x9639665933576B9Ed950214db76DF8Eb::StarStar;

    struct TokenCategory has copy,store,drop {}

    public fun register(signer: &signer){
        let address1 = @0x1001;
        let address2 = @0x1002;
        let address3 = @0x1003;
        StarStar::register_item<TokenCategory>(signer, address1);
        StarStar::register_item<TokenCategory>(signer, address2);
        StarStar::register_item<TokenCategory>(signer, address3);
    }
}

module StarStarScript{
    use 0x9639665933576B9Ed950214db76DF8Eb::StarStar;
    use 0x9639665933576B9Ed950214db76DF8Eb::StarStarToken;

    public(script) fun star<CategoryT: copy+store+drop>(signer: signer, item_address: address) : bool {
        return StarStar::star<CategoryT>(&signer, item_address)
    }

    public(script) fun unstar<CategoryT: copy+store+drop>(signer: signer, item_address: address) : bool {
        return StarStar::unstar<CategoryT>(&signer, item_address)
    }

    public(script) fun get_topn_list<CategoryT: copy+store+drop>(signer: signer){
        StarStar::get_topn_list<CategoryT>(&signer);
    }

    public(script) fun register_item<CategoryT: store+copy+drop>(signer: signer, item_address: address){
        StarStar::register_item<CategoryT>(&signer, item_address);
    }

    public(script) fun mint_token(signer: signer) {
        let default_amount = 1000000000u128;
        StarStarToken::mint(&signer, default_amount);
    }
}


}
