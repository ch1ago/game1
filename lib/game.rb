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

    class NotStartedError < GameError
    end

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

      if @model.stateless? && params[:command] != 'Start'
        raise NotStartedError
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
    attr_reader :state

    def initialize(state)
      @state = state
    end

    def stateless?
      state.nil?
    end

    def create_state_template
      @state = {
        players_order: [],
        players: {},
        commands: {},
        board: {},
      }
    end

    def add_player(player_id, hash)
      @state[:players_order] << player_id
      @state[:players][player_id] = hash
      @state[:board][player_id]   = nil
    end

    def determine_next_turn(foo)
      if foo
        next_player_id = "H1"
        @state[:commands] = {next_player_id => ['RollDice']} # next turn, untested
        next_player_id
      else
        # next_player_id = @params[:player] + 1
        next_player_id = "H2"
        @state[:commands] = {next_player_id => ['RollDice']}
        next_player_id
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

    class Factory

      class NotFoundError < GameError
      end

      def self.get_class(string)
        case string
        when 'Echo'     then Commands::Echo
        when 'Start'    then Commands::Start
        when 'RollDice' then Commands::RollDice
        when 'EndTurn'  then Commands::EndTurn
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
    end

    class Echo < Base
      def execute
        params
      end
    end

    class Start < Base
      class AlreadyStartedError < GameError
      end

      def execute
        check_unstarted!
        check_params!

        @model.create_state_template

        @params[:players].each { |pid, h| @model.add_player(pid, h) }

        @model.determine_next_turn(true)

        output = "started!"
        output
      end

      private

      def check_unstarted!
        @model.state.nil? or raise AlreadyStartedError
      end

      def check_params!
        if @params.keys != expected_params_keys
          raise InputError, "expected keys '#{expected_params_keys}',\t found keys: #{@params.keys}"
        end
      end

      def expected_params_keys
        [:command, :players]
      end
    end

    class RollDice < Base
      def execute
        output = []

        d = Dice.roll(2)

        output << "#{@params[:player]} rolled 2d6: #{d.join(', ')}."

        @model.state[:board][@params[:player]] = d
        # has_two_equal_dice = d.uniq.size==1
        # if has_two_equal_dice
        #  output << "Explosion, roll again!"
        # else
        @model.state[:commands] = {'H1' => ['EndTurn']} # untested
        # end

        output
      end
    end

    class EndTurn < Base
      def execute
        output = []

        player_id = @params[:player]
        output << "#{player_id} has ended their turn."

        next_player_id = @model.determine_next_turn(false)
        output << "#{next_player_id}, now it is your turn."

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
