require 'spec_helper'

module Sample
  RSpec.describe "The Game" do

    describe Controller do

      subject { described_class.new(model) }

      describe "with a stateless model" do

        let(:model) { double("Model", stateless?: true) }

        describe ".execute" do
          it 'raises Commands::Validations::Errors::NotStarted' do
            expect {
              subject.execute(command: 'Echo')
            }.to raise_error(Commands::Validations::Errors::NotStarted)
          end
        end

      end

      describe "with a stateful model" do

        let(:model) { double("Model", stateless?: false) }

        describe ".execute" do
          before do
            command = double
            expect(command).to receive(:validate!).and_return(nil)
            expect(command).to receive(:execute).and_return(:output)
            expect(Commands::Echo).to receive(:new).and_return(command)
          end

          it 'invokes Controller::ParamsCommandFactory.fab' do
            allow(Controller::ParamsCommandFactory).to receive(:fab).and_call_original
            subject.execute(command: 'Echo')
          end

          it 'delegates a command object, returns its output' do
            expect(subject.execute(command: 'Echo')).to eq(:output)
          end
        end

      end

    end

    describe Controller::ParamsCommandFactory do
      describe ".fab(model, params)" do

        subject { described_class.fab(model, params) }

        describe "model" do
          describe "model is nil" do
            let(:model) { Model.new(nil) }

            describe "params" do
              describe "params is nil" do
                let (:params) { nil }

                it('is invalid') { expect { subject }.to raise_error(Controller::ParamsCommandFactory::ParamsMalformed) }
              end

              describe "params is {}" do
                let (:params) { {} }

                it('is invalid') { expect { subject }.to raise_error(Controller::ParamsCommandFactory::ParamsMalformed) }
              end

              describe "params is {command: 'StartGame'}" do
                let (:params) { {command: 'StartGame'} }

                it('is invalid') { expect { subject }.to raise_error(Commands::Validations::Errors::Input) }
              end

              describe "params is {command: 'StartGame', players: []}" do
                let (:params) { {command: 'StartGame', players: []} }

                it('is valid') { expect(subject).to be_a(Commands::StartGame) }
              end
            end
          end

          describe "model is present" do
            let(:model) { Model.new({has: :something}) }

            describe "params is {command: 'StartGame'}" do
              let (:params) { {command: 'StartGame'} }

              it('is invalid') { expect { subject }.to raise_error(Commands::Validations::Errors::AlreadyStarted) }
            end
          end
        end

      end
    end

  end
end
