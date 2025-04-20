// components/sales.cairo
#[starknet::component]
mod SalesComponent {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map, StorageType};

    #[derive(Copy, Drop, Serde, starknet::Store, PartialEq)]
    #[repr(u8)]
    enum SalesStatus {
        #[default]
        None,
        Bought,
        Sold
    }

    #[storage]
    struct Storage {
        // Maps item ID to its sales status
        sales: Map<u256, SalesStatus>,
        // Maps item ID to its price
        prices: Map<u256, u256>,
        // Maps item ID to its owner
        owners: Map<u256, ContractAddress>,
        // Contract admin
        admin: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ItemListed: ItemListed,
        ItemBought: ItemBought,
        ItemSold: ItemSold
    }

    #[derive(Drop, starknet::Event)]
    struct ItemListed {
        #[key]
        item_id: u256,
        #[key]
        seller: ContractAddress,
        price: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ItemBought {
        #[key]
        item_id: u256,
        #[key]
        buyer: ContractAddress,
        price: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ItemSold {
        #[key]
        item_id: u256,
        #[key]
        seller: ContractAddress,
        #[key]
        buyer: ContractAddress,
        price: u256
    }

    #[generate_trait]
    pub trait ISalesTrait<TContractState> {
        fn list_item(ref self: TContractState, item_id: u256, price: u256);
        fn buy_item(ref self: TContractState, item_id: u256);
        fn cancel_listing(ref self: TContractState, item_id: u256);
        fn get_item_status(self: @TContractState, item_id: u256) -> SalesStatus;
        fn get_item_price(self: @TContractState, item_id: u256) -> u256;
        fn get_item_owner(self: @TContractState, item_id: u256) -> ContractAddress;
        fn initialize(ref self: TContractState, admin: ContractAddress);
    }

    #[abi(embed_v0)]
    impl SalesImpl<
        TContractState,
        impl TContractStateImpl: HasComponent<TContractState>
    > of ISalesTrait<TContractState> {
        fn list_item(ref self: TContractState, item_id: u256, price: u256) {
            // Get component
            let component = HasComponent::get_component_mut(ref self);
            let caller = get_caller_address();

            // Validations
            InternalFunctionsTrait::<TContractState, TContractStateImpl>::_assert_valid_price(price);
            
            // Check if item is already listed or sold
            let current_status = component.sales.read(item_id);
            assert(current_status == SalesStatus::None, 'Item already in sale process');
            
            // Update storage
            component.sales.write(item_id, SalesStatus::Sold);
            component.prices.write(item_id, price);
            component.owners.write(item_id, caller);
            
            // Emit event
            component.emit(ItemListed { item_id, seller: caller, price });
        }

        fn buy_item(ref self: TContractState, item_id: u256) {
            // Get component
            let component = HasComponent::get_component_mut(ref self);
            let buyer = get_caller_address();
            
            // Validations
            let status = component.sales.read(item_id);
            assert(status == SalesStatus::Sold, 'Item not for sale');
            
            let price = component.prices.read(item_id);
            let seller = component.owners.read(item_id);
            assert(buyer != seller, 'Cannot buy own item');
            
            // Here you would typically handle payment
            // For example, transfer tokens from buyer to seller
            // This is simplified and would need integration with a token component
            
            // Update storage
            component.sales.write(item_id, SalesStatus::Bought);
            component.owners.write(item_id, buyer);
            
            // Emit event
            component.emit(
                ItemBought { 
                    item_id, 
                    buyer, 
                    price
                }
            );
            
            component.emit(
                ItemSold { 
                    item_id, 
                    seller, 
                    buyer, 
                    price
                }
            );
        }

        fn cancel_listing(ref self: TContractState, item_id: u256) {
            // Get component
            let component = HasComponent::get_component_mut(ref self);
            let caller = get_caller_address();
            
            // Validations
            let status = component.sales.read(item_id);
            assert(status == SalesStatus::Sold, 'Item not listed for sale');
            
            let owner = component.owners.read(item_id);
            assert(caller == owner || caller == component.admin.read(), 'Not authorized');
            
            // Update storage
            component.sales.write(item_id, SalesStatus::None);
            
            // Additional cleanup
            // component.prices.write(item_id, 0); // Optional cleanup
        }

        fn get_item_status(self: @TContractState, item_id: u256) -> SalesStatus {
            let component = HasComponent::get_component(self);
            component.sales.read(item_id)
        }

        fn get_item_price(self: @TContractState, item_id: u256) -> u256 {
            let component = HasComponent::get_component(self);
            component.prices.read(item_id)
        }

        fn get_item_owner(self: @TContractState, item_id: u256) -> ContractAddress {
            let component = HasComponent::get_component(self);
            component.owners.read(item_id)
        }

        fn initialize(ref self: TContractState, admin: ContractAddress) {
            let component = HasComponent::get_component_mut(ref self);
            // Only allow initialization once
            assert(component.admin.read().is_zero(), 'Already initialized');
            component.admin.write(admin);
        }
    }

    // Internal functions
    #[generate_trait]
    impl InternalFunctions<
        TContractState,
        impl TComponentImpl: HasComponent<TContractState>
    > of InternalFunctionsTrait<TContractState, TComponentImpl> {
        fn _assert_valid_price(price: u256) {
            assert(price > 0, 'Price must be positive');
        }
        
        fn _assert_admin(
            self: @ComponentState<TContractState, TComponentImpl>, 
            caller: ContractAddress
        ) {
            assert(caller == self.admin.read(), 'Caller is not admin');
        }
    }
}
