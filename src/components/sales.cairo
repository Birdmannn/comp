#[starknet::component]
pub mod SalesComponent {
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use crate::interfaces::sales::{ISales, SalesStatus, SellEvent, BuyEvent};
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    pub struct Storage {
        pub sales: Map<u256, SalesStatus>,
        pub owner: ContractAddress,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Bought : BuyEvent,
        Sold : SellEvent,
    }

    #[embeddable_as(SalesImpl)]
    pub impl Sales<TContractState, +HasComponent<TContractState>> of ISales<ComponentState<TContractState>> {
         fn buy(ref self: ComponentState<TContractState>, item_id: u256) {
            assert(self.sales.entry(item_id).read() == SalesStatus::None, 'Item not available');

            self.sales.entry(item_id).write(SalesStatus::Bought);

            // Emit buy event
            self.emit(Event::Bought(BuyEvent {
                id: item_id,
                buyer: get_caller_address(),
            }));
        }

       fn sell(ref self: ComponentState<TContractState>, item_id: u256) {

        let caller = get_caller_address();
        assert(caller == self.owner.read(), 'Unauthorized seller');
        
        let current_state = self.sales.entry(item_id).read();
        assert(current_state == SalesStatus::Bought, 'Item not purchased');
        self.sales.entry(item_id).write(SalesStatus::Sold);
        
            // Emit sell event👀
        self.emit(Event::Sold(SellEvent {
           id: item_id,
            seller: caller
        }));

    }

        fn get_sales_status (self: @ComponentState<TContractState>, item_id: u256) -> SalesStatus {
            self.sales.entry(item_id).read()
        }
    }
}

