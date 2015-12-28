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
    class Factory

      class NotFoundError < GameError
      end

      def self.fab(data)
        data.is_a?(Hash) or raise NotFoundError, "data input must be a Hash, got '#{data}':#{data.class} instead"

        case data[:command]
        when 'Echo'  then return Commands::Echo.new
        when 'Start' then return Commands::Start.new
        else raise NotFoundError, "Command was '#{data[:command]}' Not Found"
        end
      end
    end

    class Echo
      def run(input, state)
        output = input
        [input, state]
      end
    end

    class Start
      class AlreadyStartedError < GameError
      end

      def run(input, state)
        check_unstarted!(state)

        state = StateFactory.fab
        output = "started!"

        [output, state]
      end

      private

      def check_unstarted!(state)
        state.nil? or raise AlreadyStartedError
      end
    end

    # class RollDice
    #   def run(input, state)
    #     output = "WIP !!! rolled 2d6"

    #     [output, state]
    #   end
    # end
  end

  class StateFactory
    def self.fab
      # {
      #   commands: {
      #     'P1' => ['RollDice']
      #   }
      # }

      {}
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
