// components/sales.cairo
#[starknet::component]
mod SalesComponent {
    use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{Map, StoragePointerReadAccess, StoragePointerWriteAccess,
    StorageMapReadAccess, StorageMapWriteAccess, };

    #[derive(Copy, Drop, Serde, starknet::Store, PartialEq)]
   
    enum SalesStatus {
        #[default]
        None,
        Listed,
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
        // Maps item ID to its seller (for when item is Listed)
        sellers: Map<u256, ContractAddress>,
        // Contract admin
        admin: ContractAddress
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ItemListed: ItemListed,
        ItemBought: ItemBought,
        ItemSold: ItemSold,
        ListingCancelled: ListingCancelled
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

    #[derive(Drop, starknet::Event)]
    struct ListingCancelled {
        #[key]
        item_id: u256,
        #[key]
        seller: ContractAddress
    }

    #[generate_trait]
    pub trait ISalesTrait<TContractState> {
        fn list_item(ref self: TContractState, item_id: u256, price: u256);
        fn buy_item(ref self: TContractState, item_id: u256);
        fn sell_item(ref self: TContractState, item_id: u256, buyer: ContractAddress);
        fn cancel_listing(ref self: TContractState, item_id: u256);
        fn get_item_status(self: @TContractState, item_id: u256) -> SalesStatus;
        fn get_item_price(self: @TContractState, item_id: u256) -> u256;
        fn get_item_owner(self: @TContractState, item_id: u256) -> ContractAddress;
        fn get_item_seller(self: @TContractState, item_id: u256) -> ContractAddress;
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
            component.sales.write(item_id, SalesStatus::Listed);
            component.prices.write(item_id, price);
            component.owners.write(item_id, caller);
            component.sellers.write(item_id, caller);
            
            // Emit event
            component.emit(ItemListed { item_id, seller: caller, price });
        }

        fn buy_item(ref self: TContractState, item_id: u256) {
            // Get component
            let component = HasComponent::get_component_mut(ref self);
            let buyer = get_caller_address();
            
            // Validations
            let status = component.sales.read(item_id);
            assert(status == SalesStatus::Listed, 'Item not listed for sale');
            
            let price = component.prices.read(item_id);
            let seller = component.sellers.read(item_id);
            assert(buyer != seller, 'Cannot buy own item');
            
            // Here you would typically handle payment
            // For example, transfer tokens from buyer to seller
            // This is simplified and would need integration with a token component
            
            // Update storage
            component.sales.write(item_id, SalesStatus::Bought);
            component.owners.write(item_id, buyer);
            
            // Emit events
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

        fn sell_item(ref self: TContractState, item_id: u256, buyer: ContractAddress) {
            // Get component
            let component = HasComponent::get_component_mut(ref self);
            let caller = get_caller_address();
            
            // Validations
            let current_status = component.sales.read(item_id);
            let owner = component.owners.read(item_id);
            
            // Ensure caller is the owner
            assert(caller == owner, 'Not the owner');
            assert(caller != buyer, 'Cannot sell to yourself');
            assert(buyer.is_non_zero(), 'Invalid buyer address');
            
            // Ensure item is not already in a sale process
            assert(
                current_status == SalesStatus::None || current_status == SalesStatus::Bought, 
                'Item in pending sale process'
            );
            
            // If no price set previously, we need to set a minimum price
            let price = if component.prices.read(item_id) == 0 {
                1 // Minimum price to avoid zero-price sales
            } else {
                component.prices.read(item_id)
            };
            
            // Update storage - direct sale without listing
            component.sales.write(item_id, SalesStatus::Sold);
            component.sellers.write(item_id, caller);
            component.owners.write(item_id, buyer);
            
            // Emit event for the direct sale
            component.emit(
                ItemSold { 
                    item_id, 
                    seller: caller, 
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
            assert(status == SalesStatus::Listed, 'Item not listed for sale');
            
            let seller = component.sellers.read(item_id);
            assert(caller == seller || caller == component.admin.read(), 'Not authorized');
            
            // Update storage
            component.sales.write(item_id, SalesStatus::None);
            
            // Emit cancellation event
            component.emit(ListingCancelled { item_id, seller });
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

        fn get_item_seller(self: @TContractState, item_id: u256) -> ContractAddress {
            let component = HasComponent::get_component(self);
            component.sellers.read(item_id)
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