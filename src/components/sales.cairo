#[starknet::component]
pub mod SalesComponent {
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use crate::interfaces::{SalesStatus, SaleEvent};
    use starknet::{ContractAddress, get_caller_address};
    use crate::interfaces::sales::ISales;

    #[storage]
    pub struct Storage {
        pub sales: Map<u256, SalesStatus>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        SaleEvent: SaleEvent
    }

    #[embeddable_as(SalesImpl)]
    pub impl Sales<
        TContractState, +HasComponent<TContractState>,
    > of ISales<ComponentState<TContractState>> {
        fn buy(ref self: ComponentState<TContractState>, item_id: u256) {
            let caller = get_caller_address();
            let current_status = self.sales.read(item_id);
            
            assert(
                current_status == SalesStatus::None || 
                matches!(current_status, SalesStatus::Sold(_)),
                'Item not available for purchase'
            );

            self.sales.write(item_id, SalesStatus::Bought(caller));
            self.emit(SaleEvent { item_id, status: SalesStatus::Bought(caller), caller });
        }

        fn sell(ref self: ComponentState<TContractState>, item_id: u256) {
            let caller = get_caller_address();
            let current_status = self.sales.read(item_id);
            
            assert(
                current_status == SalesStatus::None || 
                (matches!(current_status, SalesStatus::Bought(owner)) && owner == caller),
                'You cannot sell this item'
            );

            self.sales.write(item_id, SalesStatus::Sold(caller));
            self.emit(SaleEvent { item_id, status: SalesStatus::Sold(caller), caller });
        }

        
        fn get_status(self: @ComponentState<TContractState>, item_id: u256) -> SalesStatus {
            self.sales.read(item_id)
        }
    }
}