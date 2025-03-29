#[starknet::component]
pub mod VotingComponent {
    use starknet::storage::{
        Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};
    use crate::components::sales::{SalesImpl, SalesStatus};
    use crate::interfaces::voting::{DEFAULT_THRESHOLD, IVote, Poll, PollTrait, Voted};

    #[storage]
    pub struct Storage {
        pub polls: Map<u256, Poll>,
        pub voters: Map<(ContractAddress, u256), bool>,
        pub nonce: u256,
        pub sales: SalesImpl,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Voted: Voted
    }

    #[embeddable_as(VotingImpl)]
    pub impl Voting<
        TContractState, +HasComponent<TContractState>,
    > of IVote<ComponentState<TContractState>> {
        fn create_poll(
            ref self: ComponentState<TContractState>, name: ByteArray, desc: ByteArray,item_id: u256
        ) -> u256 {
            let id = self.nonce.read() + 1;
            assert(name != "" && desc != "", 'NAME OR DESC IS EMPTY');
            let mut poll: Poll = Default::default();
            poll.name = name;
            poll.desc = desc;
            poll.linked_item = item_id;
            self.polls.entry(id).write(poll);
            self.nonce.write(id);
            id
        }

        fn vote(ref self: ComponentState<TContractState>, support: bool, id: u256) {
            let mut poll = self.polls.entry(id).read();
            assert(poll != Default::default(), 'INVALID POLL');
            assert(poll.status == Default::default(), 'POLL NOT PENDING');
            let caller = get_caller_address();
            let has_voted = self.voters.entry((caller, id)).read();
            assert(!has_voted, 'CALLER HAS VOTED');

            match support {
                true => poll.yes_votes += 1,
                false => {
                    poll.no_votes += 1;
                    // Check if this "no" vote caused the threshold to be reached
                    let vote_count = poll.yes_votes + poll.no_votes;
                    if vote_count >= DEFAULT_THRESHOLD && poll.no_votes > poll.yes_votes {
                        // Immediately trigger sale if voting failed
                        self.sales.sell(poll.linked_item);
                        poll.status = PollStatus::Finished(false);
                    }
                }
            }

            let vote_count = poll.yes_votes + poll.no_votes;
            if vote_count >= DEFAULT_THRESHOLD {
                poll.resolve();
            }

            self.polls.entry(id).write(poll);
            self.voters.entry((caller, id)).write(true);
            self.emit(Voted { id, voter: caller });
        }

        fn get_poll(self: @ComponentState<TContractState>, id: u256) -> Poll {
            self.polls.entry(id).read()
        }
    }

    #[generate_trait]
    pub impl VoteInternalImpl<
        TContractState, +HasComponent<ComponentState<TContractState>>,
    > of VoteTrait<TContractState> {
        fn _resolve_poll(ref self: ComponentState<TContractState>, poll: Poll) {}
    }
}
