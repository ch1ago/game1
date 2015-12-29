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

    def_delegator :@model, :state

    def initialize(state)
      @model = Model.new(state)
    end

    # def state
    #   @model.state # dup.freeze ???
    # end

    def execute(params={})
      check_allowed!(params)

      command = Commands::Factory.fab(params)
      return @model.execute(command)
    end

    private

    def check_allowed!(params)
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

    def execute(command)
      result = command.execute(state)
      @state = result[1]
      return result[0]
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

      def self.fab(params)
        params.is_a?(Hash) or raise NotFoundError, "data params must be a Hash, got '#{params}':#{params.class} instead"

        klass = case params[:command]
        when 'Echo'     then Commands::Echo
        when 'Start'    then Commands::Start
        when 'RollDice' then Commands::RollDice
        else raise NotFoundError, "Command was '#{params[:command]}' Not Found"
        end

        klass.new(params)
      end
    end

    class Base
      attr_reader :params

      def initialize(params)
        @params = params
      end
    end

    class Echo < Base
      def execute(state)
        [params, state]
      end
    end

    class Start < Base
      class AlreadyStartedError < GameError
      end

      def execute(state)
        check_unstarted!(state)
        check_params!(params)

        output = "started!"

        # new state template
        state = {
          players_order: [],
          players: {},
          commands: {},
          board: {},
        }

        # fill state template
        params[:players].each do |pid, phash|
          state[:players_order] << pid
          state[:players][pid] = phash
          state[:board][pid]   = nil
        end

        # determine next turn
        state[:commands] = {'H1' => ['RollDice']} # next turn, untested

        [output, state]
      end

      private

      def check_unstarted!(state)
        state.nil? or raise AlreadyStartedError
      end

      def check_params!(params)
        if params.keys != expected_params_keys
          raise InputError, "expected keys '#{expected_params_keys}',\t found keys: #{params.keys}"
        end
      end

      def expected_params_keys
        [:command, :players]
      end
    end

    class RollDice < Base
      def execute(state)
        output = []

        d = Dice.roll(2)

        output << "#{params[:player]} rolled 2d6: #{d.join(', ')}."

        state[:board][params[:player]] = d
        # has_two_equal_dice = d.uniq.size==1
        # if has_two_equal_dice
        #  output << "Explosion, roll again!"
        # else
        state[:commands] = {'H1' => ['EndTurn']} # untested
        # end

        [output, state]
      end
    end

    class EndTurn < Base
      def execute(state)
        output = []

        player_id = params[:player]
        state[:commands][player_id] = []
        output << "#{player_id} has ended their turn."

        # next_player_id = params[:player] + 1
        next_player_id = "H2"
        output << "#{next_player_id}, now it is your turn."
        state[:commands][next_player_id] = ['RollDice']

        [output, state]
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
