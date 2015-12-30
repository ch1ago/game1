# http://patorjk.com/software/taag/#p=display&f=Banner&t=Commands

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
    extend Forwardable

    class ParamsMalformed < GameError
    end

    def_delegator :@model, :state

    def initialize(state)
      @model = Model.new(state)
    end

    # def state
    #   @model.state # dup.freeze ???
    # end

    def execute(params={})
      check!(params)

      command_class = Commands::Factory.get_class(params[:command])
      command = command_class.new(@model, params)

      command.validate!

      return command.execute
    end

    private

    def check!(params)
      if not params.is_a?(Hash)
        raise ParamsMalformed, "params must be a Hash, got '#{params}':#{params.class} instead"
      end

      if params[:command].nil?
        raise ParamsMalformed, "params must have a :command key, got '#{params}' instead"
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

  # due to delegation, no need to test model yet
  class Model
    extend Forwardable

    attr_reader :state

    def_delegator :helper, :player_id

    def initialize(state)
      @state = state
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

    def move_to_next_turn
      next_player_id = helper.get_next_player_id || helper.get_first_player_id

      @state[:turn][:player_id] = next_player_id
      @state[:turn][:commands] = ['RollDice'] # context
      next_player_id
    end

    def move_to_first_turn
      @state[:turn][:player_id] = helper.get_first_player_id
    end

    def is_last_turn?
      player_index  = @state[:players_order].index(player_id)
      players_count = @state[:players_order].count
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
        player_index  = @state[:players_order].index(player_id)
        players_count = @state[:players_order].count

        is_nil  = player_index.nil?

        if is_nil
          get_first_player_id
        else
          @state[:players_order][player_index+1]
        end
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

    class InputError < GameError
    end

    class NotStartedError < GameError
    end

    class Factory

      class NotFoundError < GameError
      end

      def self.get_class(string)
        case string
        when 'Echo'      then Commands::Echo
        when 'StartGame' then Commands::StartGame
        when 'RollDice'  then Commands::RollDice
        when 'EndTurn'   then Commands::EndTurn
        else raise NotFoundError, "Command was '#{string}' Not Found"
        end
      end
    end

    class Base
      attr_reader :params

      def initialize(model, params)
        @params = params
        @model  = model
      end

      def validate!
        # not implemented
      end

      protected

      def validates_presence_of_params!(*param_keys)
        if validates_presence_of_params(*param_keys)
          raise InputError, "expected params '#{param_keys}', but found #{@params.keys}"
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
    end

    class Base2 < Base
      def validate!
        validates_presence_of(@model.state) or raise Commands::NotStartedError
      end
    end

    class StartGame < Base2
      class AlreadyStartedError < GameError
      end

      def execute
        @model.create_state_template

        @params[:players].each { |pid, h| @model.add_player(pid, h) }

        output = []
        output << "Game Started!"
        output += StartRound.new(@model, {}).execute
        output
      end

      def validate!
        validates_blankness_of(@model.state) or raise AlreadyStartedError
        validates_presence_of_params! :command, :players
      end
    end

    class StartRound < Base2
      def execute
        output = []
        round_id = @model.state[:turn][:round].to_i
        @model.state[:turn][:round] = round_id += 1
        output << "Round #{round_id} has started."

        output += StartTurn.new(@model, {}).execute
        output
      end
    end

    class StartTurn < Base2
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

    class EndTurn < Base2
      def execute
        output = []

        player_id = @params[:player]
        output << "#{player_id} has ended their turn."

        if @model.is_last_turn?
          output += EndRound.new(@model, {}).execute
        else
          output += StartTurn.new(@model, {}).execute
        end

        output
      end
    end

    class EndRound < Base2
      def execute
        output = []

        round_id = @model.state[:turn][:round]
        output << "Round #{round_id} has ended."

        output += StartRound.new(@model, {}).execute
        output
      end
    end

    class Echo < Base2
      def execute
        params
      end
    end

    class RollDice < Base2
      def execute
        output = []

        d = Dice.roll(2)

        output << "#{@params[:player]} rolled 2d6: #{d.join(', ')}."

        @model.state[:board][@params[:player]] = d
        # has_two_equal_dice = d.uniq.size==1
        # if has_two_equal_dice
        #  output << "Explosion, roll again!"
        # else
        # @model.state[:commands] = {'H1' => ['EndTurn']} # untested
        @model.state[:turn][:commands] = ['EndTurn'] # untested
        # end

        output
      end

      def validate!
        validates_presence_of_params! :command, :player
      end

    end

    class PlayRobotTurn < Base2
      def execute
        output = []

        output << "#{@model.player_id} is a mindless Robot!"
        output << "#{@model.player_id} doesn't know what to do!"
        output += EndTurn.new(@model, {player: @model.player_id}).execute

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
