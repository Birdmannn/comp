use starknet::ContractAddress;

#[starknet::interface]
pub trait IVote<TContractState> {
    fn create_poll(ref self: TContractState, name: ByteArray, desc: ByteArray) -> u256;
    fn vote(ref self: TContractState, support: bool, id: u256);
    fn resolve_poll(ref self: TContractState, id: u256);
    fn get_poll(self: @TContractState, id: u256) -> Poll;
}

#[derive(Drop, Clone, Default, Serde, PartialEq, starknet::Store)]
pub struct Poll {
    pub name: ByteArray,
    pub desc: ByteArray,
    pub yes_votes: u256,
    pub no_votes: u256,
    pub status: PollStatus,
}

#[generate_trait]
pub impl PollImpl of PollTrait {
    fn resolve(ref self: Poll) {
        assert(self.no_votes + self.yes_votes >= DEFAULT_THRESHOLD, 'COULD NOT RESOLVE');
        let mut status = false;
        if self.yes_votes > self.no_votes {
            status = true;
        }
        self.status = PollStatus::Finished(status);
    }
}

#[derive(Drop, Copy, Default, Serde, PartialEq, starknet::Store)]
pub enum PollStatus {
    #[default]
    Pending,
    Finished: bool,
}

#[derive(Drop, starknet::Event)]
pub struct Voted {
    #[key]
    pub id: u256,
    #[key]
    pub voter: ContractAddress,
}

pub const DEFAULT_THRESHOLD: u256 = 10;
