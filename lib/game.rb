# http://patorjk.com/software/taag/#p=display&f=Banner&t=Commands

module Sample

  class GameError < StandardError
  end





  #####
 #     #  ####  #    # ##### #####   ####  #      #      ###### #####
 #       #    # ##   #   #   #    # #    # #      #      #      #    #
 #       #    # # #  #   #   #    # #    # #      #      #####  #    #
 #       #    # #  # #   #   #####  #    # #      #      #      #####
 #     # #    # #   ##   #   #   #  #    # #      #      #      #   #
  #####   ####  #    #   #   #    #  ####  ###### ###### ###### #    #

  class Controller

    class NotStartedError < GameError
    end

    attr_reader :state

    def initialize(state)
      @state = state
    end


    def input(command_data={})
      check_allowed!(command_data)

      command = Commands::Factory.fab(command_data)
      result = command.run(command_data, state)

      @state = result[1]
      return result[0]
    end

    private

    def check_allowed!(command_data)
      if @state.nil? && command_data[:command] != 'Start'
        raise NotStartedError
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

      def self.fab(data)
        data.is_a?(Hash) or raise NotFoundError, "data input must be a Hash, got '#{data}':#{data.class} instead"

        case data[:command]
        when 'Echo'  then return Commands::Echo.new
        when 'Start' then return Commands::Start.new
        when 'RollDice' then return Commands::RollDice.new
        else raise NotFoundError, "Command was '#{data[:command]}' Not Found"
        end
      end
    end

    class Echo
      def run(input, state)
        [input, state]
      end
    end

    class Start
      class AlreadyStartedError < GameError
      end

      def run(input, state)
        check_unstarted!(state)
        check_input!(input)

        output = "started!"

        # new state template
        state = {
          players_order: [],
          players: {},
          commands: {},
          board: {},
        }

        # fill state template
        input[:players].each do |pid, phash|
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

      def check_input!(input)
        if input.keys != expected_input_keys
          raise InputError, "expected keys '#{expected_input_keys}',\t found keys: #{input.keys}"
        end
      end

      def expected_input_keys
        [:command, :players]
      end
    end

    class RollDice
      def run(input, state)
        output = []

        d = Dice.roll(2)

        output << "#{input[:player]} rolled 2d6: #{d.join(', ')}."

        state[:board][input[:player]] = d
        # has_two_equal_dice = d.uniq.size==1
        # if has_two_equal_dice
        #  output << "Explosion, roll again!"
        # else
        state[:commands] = {'H1' => ['EndTurn']} # untested
        # end

        [output, state]
      end
    end

    class EndTurn
      def run(input, state)
        output = []

        player_id = input[:player]
        state[:commands][player_id] = []
        output << "#{player_id} has ended their turn."

        # next_player_id = input[:player] + 1
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
