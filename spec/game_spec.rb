require 'spec_helper'

module Sample
RSpec.describe "The Game" do

  describe "Unit Tests" do

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

        describe ".input" do
          it 'raises Sample::Controller::NotStartedError' do
            expect {
              subject.input(some: :args)
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

        describe ".input" do

          before do
            command = double('double', run: [:output, :new_state])
            expect(Commands::Factory).to receive(:fab).and_return(command)
          end

          it 'delegates a command object, created by delegating to Commands::Factory' do
            subject.input(:args)
          end

          it 'delegates a command object, returns its output' do
            expect(subject.input(:args)).to eq(:output)
          end

          it 'delegates a command object, changes controller state' do
            expect {
              subject.input(:args)
            }.to change { subject.state }.from(initial_state).to(:new_state)
          end
        end

      end

    end

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
          subject { Commands::Factory.fab(command: 'Start') }

          it('returns a Start command') { expect(subject).to be_a(Commands::Start) }
        end

      end
    end

    describe Commands::Echo do
      describe '.run' do
        let(:result) { subject.run(:input, :current_state) }

        it('returns[0] (the output) as the same input data') { expect(result[0]).to eq(:input) }
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

  describe "Integration Tests" do
    describe Controller do

      subject { Controller.new(nil) }

      describe "Any Command" do
        describe "called before Start" do
          it 'raises Sample::Controller::NotStartedError' do
            expect {
              subject.input({command: 'Echo'})
            }.to raise_error(Sample::Controller::NotStartedError)
          end
        end
      end

      describe "Command Start" do
        before do
          expect {
            expect( subject.input({command: 'Start'}) ).to eq('started!')
          }.to change { subject.state }.from(nil).to({})
        end

        it "called first time, returns started, sets first state" do
        end

        it "called second, raises error, does not change state" do
          expect {
            expect { subject.input({command: 'Start'}) }.to raise_error(Commands::Start::AlreadyStartedError)
          }.not_to change { subject.state }
        end
      end

      describe "Command RollDice" do
        before do
          expect( subject.input({command: 'Start'}) ).to eq('started!')
          expect( Dice ).to receive(:roll).and_return([1,2])
        end

        let(:input) { {command: 'RollDice', player: "H1"} }

        it "changes the state" do
          expect {
            subject.input(input)
          }.to change { subject.state[:last_roll] }.from(nil).to([1,2])
        end

        it "outputs the roll result" do
          expect( subject.input(input) ).to include("H1 rolled 2d6: 1, 2")
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
