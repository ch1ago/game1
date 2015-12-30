require 'spec_helper'

GOOD_START_COMMAND_PLAYERS_INPUT = {
  'H1' => {brain: :human, color: :blue},
  'H2' => {brain: :human, color: :red},
  'R3' => {brain: :robot, color: :green},
}

BAD_START_COMMAND_INPUT  = {command: 'StartGame'}
GOOD_START_COMMAND_INPUT = {
  command: 'StartGame',
  players: GOOD_START_COMMAND_PLAYERS_INPUT
}

module Sample
RSpec.describe "The Game" do

                #     #
                #     # #    # # #####
                #     # ##   # #   #
 ##### #####    #     # # #  # #   #
                #     # #  # # #   #
                #     # #   ## #   #
                 #####  #    # #   #


  describe "Unit Tests" do

  #####
 #     #  ####  #    # ##### #####   ####  #      #      ###### #####
 #       #    # ##   #   #   #    # #    # #      #      #      #    #
 #       #    # # #  #   #   #    # #    # #      #      #####  #    #
 #       #    # #  # #   #   #####  #    # #      #      #      #####
 #     # #    # #   ##   #   #   #  #    # #      #      #      #   #
  #####   ####  #    #   #   #    #  ####  ###### ###### ###### #    #

    describe Controller do

      subject { described_class.new(initial_state) }

      describe "with state = nil" do

        let(:initial_state) { nil }

        describe ".new" do
          it 'returns Controller' do
            expect(subject).to be_a(Controller)
          end
        end

        describe ".state" do
          it 'returns the current state' do
            expect(subject.state).to eq(nil)
          end
        end

        describe ".execute" do
          it 'raises Sample::Commands::NotStartedError' do
            expect {
              subject.execute(command: 'Echo')
            }.to raise_error(Sample::Commands::NotStartedError)
          end
        end

      end

      describe 'with state = {has_state: true}' do

        let(:initial_state) { {has_state: true} }

        describe ".new" do
          it 'returns Controller' do
            expect(subject).to be_a(Controller)
          end
        end

        describe ".state" do
          it 'returns the current state' do
            expect(subject.state).to eq({has_state: true})
          end
        end

        describe ".execute" do
          before do
            command = double
            expect(command).to receive(:validate!).and_return(nil)
            expect(command).to receive(:execute).and_return(:output)
            expect(Commands::Echo).to receive(:new).and_return(command)
          end

          it 'invokes Commands::Factory.get_class' do
            allow(Commands::Factory).to receive(:get_class).and_call_original
            subject.execute(command: 'Echo')
          end

          it 'delegates a command object, returns its output' do
            expect(subject.execute(command: 'Echo')).to eq(:output)
          end
        end

      end

    end

  #####
 #     #  ####  #    # #    #   ##   #    # #####   ####
 #       #    # ##  ## ##  ##  #  #  ##   # #    # #
 #       #    # # ## # # ## # #    # # #  # #    #  ####
 #       #    # #    # #    # ###### #  # # #    #      #
 #     # #    # #    # #    # #    # #   ## #    # #    #
  #####   ####  #    # #    # #    # #    # #####   ####

    describe "Commands" do
      describe Commands::Factory do
        describe ".get_class" do

          describe "with 'blank'" do
            subject { Commands::Factory.get_class('') }

            it('is invalid') { expect { subject }.to raise_error(Commands::Factory::NotFoundError) }
          end

          describe "with 'Echo'" do
            subject { Commands::Factory.get_class('Echo') }

            it('returns a Echo command') { expect(subject).to eq(Commands::Echo) }
          end

          describe "with 'StartGame'" do
            subject { Commands::Factory.get_class('StartGame') }

            it('returns a StartGame command') { expect(subject).to eq(Commands::StartGame) }
          end

        end
      end

      describe Commands::Echo do
        describe '.execute' do
          subject { described_class.new(:current_state, :params) }

          it('returns params') { expect(subject.execute).to eq(:params) }
        end
      end

      describe Commands::StartGame do
        pending "Check Integration Tests"
      end

      describe Commands::RollDice do
        pending "Check Integration Tests"
      end

      describe Commands::EndTurn do
        pending "Check Integration Tests"
      end
    end
  end











                ###
                 #  #    # ##### ######  ####  #####    ##   ##### #  ####  #    #
                 #  ##   #   #   #      #    # #    #  #  #    #   # #    # ##   #
 ##### #####     #  # #  #   #   #####  #      #    # #    #   #   # #    # # #  #
                 #  #  # #   #   #      #  ### #####  ######   #   # #    # #  # #
                 #  #   ##   #   #      #    # #   #  #    #   #   # #    # #   ##
                ### #    #   #   ######  ####  #    # #    #   #   #  ####  #    #


  describe "Integration Tests" do
    describe Controller do

      subject { Controller.new(nil) }

      describe "Any Command" do
        describe "called before Start" do
          it 'raises Sample::Commands::NotStartedError' do
            expect {
              subject.execute({command: 'Echo'})
            }.to raise_error(Sample::Commands::NotStartedError)
          end
        end
      end

      describe "Command Start" do
        before do
          expect {
            expect( subject.execute(GOOD_START_COMMAND_INPUT) ).to include('Game Started!')
          }.to change { subject.state }.from(nil) #.to({})
        end

        it "called first time, returns started, sets first state" do
          expect(subject.state.keys).to            match_array([:players_order, :players, :board, :turn])
          expect(subject.state[:players_order]).to eq(["H1", "H2", "R3"])
          expect(subject.state[:players]).to       eq(GOOD_START_COMMAND_PLAYERS_INPUT)
          expect(subject.state[:board]).to         eq({"H1"=>nil, "H2"=>nil, "R3"=>nil})

          expect(subject.state[:turn].keys).to        match_array([:player_id, :commands, :round])
          expect(subject.state[:turn][:round]).to eq(1)
          expect(subject.state[:turn][:player_id]).to eq("H1")
          expect(subject.state[:turn][:commands]).to  eq(["RollDice"])
        end

        it "called second, raises error, does not change state" do
          expect {
            expect { subject.execute(GOOD_START_COMMAND_INPUT) }.to raise_error(Commands::StartGame::AlreadyStartedError)
          }.not_to change { subject.state }
        end
      end

      describe "Command RollDice" do
        before do
          expect( subject.execute(GOOD_START_COMMAND_INPUT) ).to include('Game Started!')
          expect( Dice ).to receive(:roll).and_return([1,2])
        end

        let(:params) { {command: 'RollDice', player: "H1"} }

        it "changes the state of the board" do
          new_board = {"H1"=>[1, 2], "H2"=>nil, "R3"=>nil}

          expect { subject.execute(params) }.to change { subject.state[:board] }.to(new_board)
        end

        it "changes the state of the commands" do
          new_commands = {:player_id=>"H1", :round=>1, :commands=>["EndTurn"]}

          expect { subject.execute(params) }.to change { subject.state[:turn] }.to(new_commands)
        end

        it "outputs the roll result" do
          expect( subject.execute(params) ).to include("H1 rolled 2d6: 1, 2.")
        end
      end

      describe "Command EndTurn" do
        before do
          expect( subject.execute(GOOD_START_COMMAND_INPUT) ).to include('Game Started!')
        end

        let(:params) { {command: 'EndTurn', player: "H1"} }

        it "outputs the end turn" do
          expect( subject.execute(params) ).to include("H1 has ended their turn.")
        end

        it "outputs the next turn" do
          expect( subject.execute(params) ).to include("H2, now it is your turn.")
        end

        it "determines the next player" do
          expect(subject.state[:turn]).to eq(:player_id=>"H1", :round=>1, :commands=>["RollDice"])
          subject.execute(params)
          expect(subject.state[:turn]).to eq(:player_id=>"H2", :round=>1, :commands=>["RollDice"])
        end
      end

      describe "A Full Round" do
        it "WIP" do
          expect( subject.execute(GOOD_START_COMMAND_INPUT) ).to include('Game Started!')
          expect( subject.execute(command: 'EndTurn', player: "H1") ).to eq(["H1 has ended their turn.", "H2, now it is your turn."])
          expect( subject.execute(command: 'EndTurn', player: "H1") ).to eq(["H1 has ended their turn.", "R3, now it is your turn.", "R3 is a mindless Robot!", "R3 doesn't know what to do!", "R3 has ended their turn.", "Round 1 has ended.", "Round 2 has started.", "H1, now it is your turn."])
        end
      end

    end
  end








  # describe Player do
  #   let(:controller) { Controller.new }

  #   it ".new" do
  #     expect(Player.new(controller, "P1")).to be_a(Player)
  #     expect(controller.players.count).to eq(1)
  #   end

  # end

end
end
