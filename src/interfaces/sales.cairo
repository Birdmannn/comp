
use starknet::ContractAddress;

#[starknet::interface]
pub trait ISales<TContractState> {
    fn buy(ref self: TContractState, item_id: u256);
    fn sell(ref self: TContractState, item_id: u256);
    fn get_sales_status(self: @TContractState, item_id: u256) -> SalesStatus;
}

#[derive(Drop, Copy, Default, Serde, PartialEq, starknet::Store)]

pub enum SalesStatus {
    #[default]
    None,
    Bought,
    Sold,
}

#[storage]
pub struct Storage {
    sales_status: Map<u256, SalesStatus>,
}


    #[derive(Drop, starknet::Event)]
    pub struct BuyEvent {
        #[key]
        pub id: u256,
        #[key]
        pub buyer: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    pub struct SellEvent {
        #[key]
        pub id: u256,
        #[key]
        pub seller: ContractAddress,
    }