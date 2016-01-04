require 'spec_helper'

module Sample
  RSpec.describe "The Game" do

    describe Model do

      describe "ClassMethods" do
        describe ".new" do

          describe "with state = nil" do
            let(:state) { nil }
            it 'returns a Model' do
              expect(described_class.new(state)).to be_a(Model)
            end
          end

          describe "with state = nil" do
            let(:state) { {"has_state" => true} }
            it 'returns a Model' do
              expect(described_class.new(state)).to be_a(Model)
            end
          end

        end
      end

      describe "LoadableState" do

        subject { Model.new(nil) }

        describe ".unload & .load(string)" do
          let(:original_state_as_hash) { {"has" => "something"} }
          let(:original_state_as_unloaded_string) { Model.new(original_state_as_hash).unload }

          it "matches the original state" do
            new_state = subject.load(original_state_as_unloaded_string).state
            expect(new_state).to eq(original_state_as_hash)
          end

          it "works with files" do
            file_path = File.join(ROOT, "tmp/#{Time.now.to_s}.json")

            File.write(file_path, original_state_as_unloaded_string)
            new_state = File.read(file_path)

            new_state = subject.load(new_state).state
            expect(new_state).to eq(original_state_as_hash)
          end
        end
      end

    end

  end
end
