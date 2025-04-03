use starknet::ContractAddress;

#[starknet::interface]
pub trait ISales<TContractState> {
    fn buy(ref self: TContractState, item_id: u256);
    fn sell(ref self: TContractState, item_id: u256);
    fn get_status(self: @TContractState, item_id: u256) -> SalesStatus;
}

#[derive(Drop, Copy, Serde, starknet::Store, PartialEq)]
pub enum SalesStatus {
    #[default]
    None,
    Bought: ContractAddress,
    Sold: ContractAddress
}

#[derive(Drop, starknet::Event)]
pub struct SaleEvent {
    #[key]
    pub item_id: u256,
    pub status: SalesStatus,
    pub caller: ContractAddress
}