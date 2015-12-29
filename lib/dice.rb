class Dice

  def self.roll(n, sides=6)
    (@@i ||= new).roll(n, sides)
  end

  def roll(n, sides)
    r = []
    n.times { r << get_dice(sides).sample }
    r
  end

  private

  def get_dice(sides)
    dice_bag[sides] ||= (1..sides).to_a
  end

  def dice_bag
    @dice_bag ||= {}
  end

end
