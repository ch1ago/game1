require 'spec_helper'

module Sample
  RSpec.describe "The Game" do

    describe "Commands" do
      describe Commands::Echo do
        describe '.execute' do
          subject { described_class.new(:model, :params) }

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
end
