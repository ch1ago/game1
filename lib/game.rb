# http://patorjk.com/software/taag/#p=display&f=Banner&t=Commands

require 'singleton'
require 'json'
require 'active_support'
require 'active_support/all'
# require 'active_support/core_ext'

module Sample

  class GameError < StandardError
  end


  # Controller:
  # constructor(state): receives a state, which may be nil
  # state: returns the state
  # execute(params):
  #   - receives a Hash with command instructions
  #   - fabricates the Command instance
  #   - delegates it's execution to the model
  #   - changes its 'state'
  #   - returns 'output'


  # Model:
  # constructor(state): receives a state, which may be nil
  # state: returns the 'state'
  # execute(command):
  #   - receives a 'command'
  #   - delegates to the 'command'
  #   - changes its 'state'
  #   - returns 'output'

  # Command:
  # constructor: receives the 'params', a hash with instructions the implementation will consume
  # execute(state):
  #   - receives the 'state'
  #   - changes the 'state' using 'params'
  #   - returns 'output'

  #####
 #     #  ####  #    # ##### #####   ####  #      #      ###### #####
 #       #    # ##   #   #   #    # #    # #      #      #      #    #
 #       #    # # #  #   #   #    # #    # #      #      #####  #    #
 #       #    # #  # #   #   #####  #    # #      #      #      #####
 #     # #    # #   ##   #   #   #  #    # #      #      #      #   #
  #####   ####  #    #   #   #    #  ####  ###### ###### ###### #    #

  class Controller

    def initialize(model)
      @model = model
    end

    def execute(params={})
      command = ParamsCommandFactory.fab(@model, params)
      command.execute
    end

    class ParamsCommandFactory
      include Singleton

      class ParamsMalformed < GameError
      end

      class NotFoundError < GameError
      end

      def self.fab(model, params)
        instance.check!(params)

        klass = instance.get_class(params[:command])

        klass.new(model, params).tap(&:validate!)
      end

      def get_class(string)
        case string
        when 'Echo'      then Commands::Echo
        when 'StartGame' then Commands::StartGame
        when 'RollDice'  then Commands::RollDice
        when 'SkipTurn'  then Commands::SkipTurn
        else raise NotFoundError, "Command was '#{string}' Not Found"
        end
      end

      def check!(params)
        if not params.is_a?(Hash)
          raise ParamsMalformed, "params must be a Hash, got '#{params}':#{params.class} instead"
        end

        if params[:command].nil?
          raise ParamsMalformed, "params must have a :command key, got '#{params}' instead"
        end
      end
    end

  end


 #     #
 ##   ##  ####  #####  ###### #
 # # # # #    # #    # #      #
 #  #  # #    # #    # #####  #
 #     # #    # #    # #      #
 #     # #    # #    # #      #
 #     #  ####  #####  ###### ######

  class Model
    extend Forwardable
    def_delegators :helper, :player_id, :ordered_player_keys, :players_count

    module Concerns
      module LoadableState
        def load(string)
          @state = JSON.parse(string)
          self
        end

        def unload
          state.to_json
        end
      end
    end

    include Concerns::LoadableState

    attr_reader :state

    def initialize(state)
      @state = state && state.with_indifferent_access
    end

    def helper
      @helper ||= Helper.new(state)
    end

    def stateless?
      state.nil?
    end

    def create_state_template
      @state = {
        players_order: [],
        players: {},
        turn: {
          player_id: nil,
          # context: 'Sort',
          round: 0,
          commands: []
        },
        board: {},
      }
    end

    def add_player(player_id, hash)
      @state[:players_order] << player_id
      @state[:players][player_id] = hash
      @state[:board][player_id]   = nil
    end

    def increase_round
      @state[:turn][:round] = round + 1
    end

    def round
      @state[:turn][:round].to_i
    end

    def move_to_next_turn
      next_player_id = helper.get_next_player_id || helper.get_first_player_id

      @state[:turn][:player_id] = next_player_id
      @state[:turn][:commands] = ['RollDice'] # context SomethingMadeUp
      next_player_id
    end

    def move_to_first_turn
      @state[:turn][:player_id] = helper.get_first_player_id
    end

    def is_last_turn?
      player_index  = ordered_player_keys.index(player_id)
      player_index == players_count-1
    end

    def current_player_robot?
      @state[:players][player_id][:brain] == :robot
    end

    class Helper
      attr_reader :state

      def initialize(state)
        @state = state
      end

      def get_next_player_id
        player_index  = ordered_player_keys.index(player_id)

        if player_index.nil?
          get_first_player_id
        else
          ordered_player_keys[player_index+1]
        end
      end

      def ordered_player_keys
        @state[:players_order]
      end

      def players_count
        ordered_player_keys.count
      end

      def get_first_player_id
        @state[:players_order].first
      end

      def player_id
        @state[:turn][:player_id]
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

  module Commands

    module Validations
      module Errors
        class Input < GameError
        end

        class NotStarted < GameError
        end

        # untested
        class NotYourTurn < GameError
        end

        class AlreadyStarted < GameError
        end
      end

      module Methods
        def validates_presence_of_params!(*param_keys)
          if validates_presence_of_params(*param_keys)
            raise Commands::Validations::Errors::Input, "expected params '#{param_keys}', but found #{@params.keys}"
          end
        end

        def validates_presence_of_params(*param_keys)
          @params.keys != param_keys
        end

        def validates_blankness_of(*values)
          values.map(&:nil?).inject(:&)
        end

        def validates_presence_of(*values)
          values = [true] + values
          values.inject(:&)
        end

        def validates_equality_of(a, b)
          !a.nil? && a == b
        end

        def validates_started!
          @model.stateless? and raise Commands::Validations::Errors::NotStarted
        end

        def validates_turn! # untested
          if not validates_equality_of(@params[:player], @model.player_id)
            raise Commands::Validations::Errors::NotYourTurn, "#{@params[:player]}, this is #{@model.player_id} turn."
          end
        end
      end
    end

    class Base
      include Commands::Validations::Methods

      attr_reader :params

      def initialize(model, params)
        @params = params
        @model  = model
      end

      def validate!
        # not implemented
      end
    end

    class StartGame < Base
      def execute
        @model.create_state_template

        @params[:players].each { |pid, h| @model.add_player(pid, h) }

        output = []
        output << "Game Started!"
        output += StartRound.new(@model, {}).execute
        output
      end

      def validate!
        validates_blankness_of(@model.state) or raise Commands::Validations::Errors::AlreadyStarted
        validates_presence_of_params! :command, :players
      end
    end

    class StartRound < Base
      def execute
        output = []

        round = @model.increase_round
        output << "Round #{round} has started."

        output += StartTurn.new(@model, {}).execute
        output
      end
    end

    class StartTurn < Base
      def execute
        output = []

        next_player_id = @model.move_to_next_turn
        output << "#{next_player_id}, now it is your turn."

        if @model.current_player_robot?
          output += PlayRobotTurn.new(@model, {}).execute
        end

        output
      end
    end

    class EndTurn < Base
      def execute
        output = []

        output << "#{@model.player_id} has ended their turn."

        if @model.is_last_turn?
          output += EndRound.new(@model, {}).execute
        else
          output += StartTurn.new(@model, {}).execute
        end

        output
      end

      def validate!
        validates_started!
        validates_presence_of_params! :command, :player
        validates_turn! # untested
      end
    end

    class EndRound < Base
      def execute
        output = []

        round = @model.round
        output << "Round #{round} has ended."

        output += StartRound.new(@model, {}).execute
        output
      end
    end

    class Echo < Base
      def execute
        params
      end

      def validate!
        validates_started!
      end
    end

    class RollDice < Base
      def execute
        output = []

        d = Dice.roll(2)

        output << "#{@model.player_id} rolled 2d6: #{d.join(', ')}."

        @model.state[:board][@model.player_id] = d
        # has_two_equal_dice = d.uniq.size==1
        # if has_two_equal_dice
        #  output << "Explosion, roll again!"
        # else
        # @model.state[:commands] = {'H1' => ['EndTurn']} # untested
        @model.state[:turn][:commands] = ['SomethingMadeUp'] # untested
        # end

        output
      end

      def validate!
        validates_started!
        validates_presence_of_params! :command, :player
        validates_turn!
      end
    end

    class SkipTurn < Base
      def execute
        output = []

        d = [1, 1]

        output << "#{@model.player_id} skipped their turn."
        output << "#{@model.player_id} rolled 2d6: #{d.join(', ')}."
        output += EndTurn.new(@model, {player: @model.player_id}).execute

        output
      end
    end

    class PlayRobotTurn < Base
      def execute
        output = []

        output << "#{@model.player_id} is a brainless Robot!"
        output << "#{@model.player_id} doesn't know what to do!"
        output += SkipTurn.new(@model, {player: @model.player_id}).execute

        output
      end
    end

  end





 ######
 #     # #        ##   #   # ###### #####
 #     # #       #  #   # #  #      #    #
 ######  #      #    #   #   #####  #    #
 #       #      ######   #   #      #####
 #       #      #    #   #   #      #   #
 #       ###### #    #   #   ###### #    #





  # class Player

  #   def initialize(game, key)
  #     @game, @key = game, key
  #     @game.players << self
  #   end

  # end

  # class HumanPlayer < Player

  #   def initialize(key)
  #     super(key)
  #   end

  # end

  # class RobotPlayer < Player

  #   def initialize(key)
  #     super(key)
  #   end

  # end

end
