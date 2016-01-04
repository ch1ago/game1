require 'spec_helper'

module Sample
  RSpec.describe "Integration" do
    describe Controller do

      let(:model) { Model.new(nil) }
      subject { Controller.new(model) }

      describe "Commands" do
        describe "Any Command" do
          describe "called before Start" do
            it 'raises Commands::Validations::Errors::NotStarted' do
              expect {
                subject.execute({command: 'Echo'})
              }.to raise_error(Commands::Validations::Errors::NotStarted)
            end
          end
        end

        describe "Command Start" do
          before do
            expect {
              expect( subject.execute(GOOD_START_COMMAND_INPUT) ).to include('Game Started!')
            }.to change { model.state }.from(nil) #.to({})
          end

          it "called first time, returns started, sets first state" do
            expect(model.state.keys).to            match_array([:players_order, :players, :board, :turn])
            expect(model.state[:players_order]).to eq(["H1", "H2", "R3"])
            expect(model.state[:players]).to       eq(GOOD_START_COMMAND_PLAYERS_INPUT)
            expect(model.state[:board]).to         eq({"H1"=>nil, "H2"=>nil, "R3"=>nil})

            expect(model.state[:turn].keys).to        match_array([:player_id, :commands, :round])
            expect(model.state[:turn][:round]).to eq(1)
            expect(model.state[:turn][:player_id]).to eq("H1")
            expect(model.state[:turn][:commands]).to  eq(["RollDice"])
          end

          it "called second, raises error, does not change state" do
            expect {
              expect { subject.execute(GOOD_START_COMMAND_INPUT) }.to raise_error(Commands::Validations::Errors::AlreadyStarted)
            }.not_to change { model.state }
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

            expect { subject.execute(params) }.to change { model.state[:board] }.to(new_board)
          end

          it "changes the state of the commands" do
            new_commands = {:player_id=>"H1", :round=>1, :commands=>["SomethingMadeUp"]}

            expect { subject.execute(params) }.to change { model.state[:turn] }.to(new_commands)
          end

          it "outputs the roll result" do
            expect( subject.execute(params) ).to include("H1 rolled 2d6: 1, 2.")
          end
        end

        describe "Command SkipTurn" do
          before do
            expect( subject.execute(GOOD_START_COMMAND_INPUT) ).to include('Game Started!')
          end

          let(:params) { {command: 'SkipTurn', player: "H1"} }

          it "outputs the end turn" do
            expect( subject.execute(params) ).to include("H1 has ended their turn.")
          end

          it "outputs the next turn" do
            expect( subject.execute(params) ).to include("H2, now it is your turn.")
          end

          it "determines the next player" do
            expect(model.state[:turn]).to eq(:player_id=>"H1", :round=>1, :commands=>["RollDice"])
            subject.execute(params)
            expect(model.state[:turn]).to eq(:player_id=>"H2", :round=>1, :commands=>["RollDice"])
          end
        end
      end

      describe "A Full Round" do
        it "Works" do
          expect( subject.execute(GOOD_START_COMMAND_INPUT) ).to include('Game Started!')
          expect( subject.execute(command: 'SkipTurn', player: "H1") ).to eq([
            "H1 skipped their turn.",
            "H1 rolled 2d6: 1, 1.",
            "H1 has ended their turn.",
            "H2, now it is your turn."
          ])
          expect( subject.execute(command: 'SkipTurn', player: "H2") ).to eq([
            "H2 skipped their turn.",
            "H2 rolled 2d6: 1, 1.",
            "H2 has ended their turn.",
            "R3, now it is your turn.",
            "R3 is a brainless Robot!",
            "R3 doesn't know what to do!",
            "R3 skipped their turn.",
            "R3 rolled 2d6: 1, 1.",
            "R3 has ended their turn.",
            "Round 1 has ended.",
            "Round 2 has started.",
            "H1, now it is your turn."
          ])
        end
      end

      describe "Load & Unload State" do
        before do
          expect( subject.execute(GOOD_START_COMMAND_INPUT) ).to include('Game Started!')
        end

        let(:params) { {command: 'SkipTurn', player: "H1"} }

        it "Works Unreloaded" do
          expect( subject.execute(params) ).to include("H1 has ended their turn.")
        end

        it "Works Reloaded" do
          state = model.state.dup
          expect(state).to eq(model.state)
          # puts state.to_json
          puts state = JSON.load(state.to_json)

          subject2 = Controller.new(Model.new(state))

          expect( subject2.execute(params) ).to include("H1 has ended their turn.")
        end
      end


    end
  end
end
