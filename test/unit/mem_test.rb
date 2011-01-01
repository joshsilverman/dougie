require 'test_helper'

class MemTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_update_reviewed

    #setup
    mem = Mem.create()
    puts mem.updated_at
    mem.update_attribute(:updated_at, mem.updated_at - 60*60*24*2)
    updated_at_pre = mem.updated_at

    #request data
    params = Hash.new
    params[:id] = mem.id
    params[:confidence] = 9
    params[:importance] = 6

    #controller invokation
    mem = Mem.find(params[:id])
    mem.update_reviewed(params[:confidence], params[:importance])

    #assertions
    strength_pre = (-1) * (Time.now - updated_at_pre) / Math.log(params[:confidence].to_f/10)
    review_after = Time.now + (-1) * (strength_pre * 1.1) * Math.log(0.8)
    strength_deviation = (strength_pre - mem.strength).abs/mem.strength
    review_deviation = (review_after.to_f - mem.review_after.to_f).abs / mem.review_after.to_f

    assert(strength_deviation < 0.01)
    assert(review_deviation < 0.01)
  end
end
