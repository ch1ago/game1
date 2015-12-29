require 'spec_helper'

GOOD_START_COMMAND_PLAYERS_INPUT = {
  'H1' => {brain: :human, color: :blue},
  'H2' => {brain: :human, color: :red},
  'R3' => {brain: :robot, color: :green},
}

BAD_START_COMMAND_INPUT  = {command: 'Start'}
GOOD_START_COMMAND_INPUT = {
  command: 'Start',
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
          it 'raises Sample::Controller::NotStartedError' do
            expect {
              subject.execute(some: :args)
            }.to raise_error(Sample::Controller::NotStartedError)
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
            command = double('double', execute: [:output, :new_state])
            expect(Commands::Factory).to receive(:fab).and_return(command)
          end

          it 'delegates a command object, created by delegating to Commands::Factory' do
            subject.execute(:args)
          end

          it 'delegates a command object, returns its output' do
            expect(subject.execute(:args)).to eq(:output)
          end

          it 'delegates a command object, changes controller state' do
            expect {
              subject.execute(:args)
            }.to change { subject.state }.from(initial_state).to(:new_state)
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
        describe ".fab" do

          describe "with 'blank'" do
            subject { Commands::Factory.fab(command: '') }

            it('is invalid') { expect { subject }.to raise_error(Commands::Factory::NotFoundError) }
          end

          describe "with 'Echo'" do
            subject { Commands::Factory.fab(command: 'Echo') }

            it('returns a Echo command') { expect(subject).to be_a(Commands::Echo) }
          end

          describe "with 'Start'" do
            subject { Commands::Factory.fab(GOOD_START_COMMAND_INPUT) }

            it('returns a Start command') { expect(subject).to be_a(Commands::Start) }
          end

        end
      end

      describe Commands::Echo do
        describe '.execute' do
          subject { described_class.new(:params) }
          let(:result) { subject.execute(:current_state) }

          it('returns[0] (the output) as the same params data') { expect(result[0]).to eq(:params) }
          it('returns[1] (the new state) as the same current state') { expect(result[1]).to eq(:current_state) }
        end
      end

      describe Commands::Start do
        pending "Check Integration Tests"
      end

      describe Commands::RollDice do
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
          it 'raises Sample::Controller::NotStartedError' do
            expect {
              subject.execute({command: 'Echo'})
            }.to raise_error(Sample::Controller::NotStartedError)
          end
        end
      end

      describe "Command Start" do
        before do
          expect {
            expect( subject.execute(GOOD_START_COMMAND_INPUT) ).to eq('started!')
          }.to change { subject.state }.from(nil) #.to({})
        end

        it "called first time, returns started, sets first state" do
          expect(subject.state.keys).to match_array([:players_order, :players, :commands, :board])
          expect(subject.state[:players_order]).to eq(["H1", "H2", "R3"])
          expect(subject.state[:players]).to       eq(GOOD_START_COMMAND_PLAYERS_INPUT)
          expect(subject.state[:commands]).to      eq({"H1"=>["RollDice"]})
          expect(subject.state[:board]).to         eq({"H1"=>nil, "H2"=>nil, "R3"=>nil})
        end

        it "called second, raises error, does not change state" do
          expect {
            expect { subject.execute(GOOD_START_COMMAND_INPUT) }.to raise_error(Commands::Start::AlreadyStartedError)
          }.not_to change { subject.state }
        end
      end

      describe "Command RollDice" do
        before do
          expect( subject.execute(GOOD_START_COMMAND_INPUT) ).to eq('started!')
          expect( Dice ).to receive(:roll).and_return([1,2])
        end

        let(:params) { {command: 'RollDice', player: "H1"} }

        it "changes the state of the board" do
          new_board = {"H1"=>[1, 2], "H2"=>nil, "R3"=>nil}

          expect { subject.execute(params) }.to change { subject.state[:board] }.to(new_board)
        end

        it "changes the state of the commands" do
          new_commands = {"H1"=>["EndTurn"]}

          expect { subject.execute(params) }.to change { subject.state[:commands] }.to(new_commands)
        end

        it "outputs the roll result" do
          expect( subject.execute(params) ).to include("H1 rolled 2d6: 1, 2.")
        end

        # it "" do
        # end
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
