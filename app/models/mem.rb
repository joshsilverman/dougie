class Mem < ActiveRecord::Base
  
  belongs_to :line
  belongs_to :user

  has_many :reps

  def update_reviewed(confidence, importance)

    # calculate time delta
    time_delta_to_now = Time.now - self.updated_at

    # calculate strength_pre or strength before this repetition
    strength_pre = (-1) * time_delta_to_now / Math.log(confidence.to_f/10)

    # temp strength_post, strength_next
    strength_growth_factor = 1.1
    strength_post = strength_pre * strength_growth_factor
    strength_next_target = 0.8

    # calculate reviewAfter
    time_delta_to_next = (-1) * strength_post * Math.log(strength_next_target)
    review_after = Time.now + time_delta_to_next

    # override prediction model if confidence is 1
    if (confidence == "1")
      confidence == 0.0001
      review_after = Time.now;
      strength_pre = 0;
    end

    # update attributes
    self.update_attributes(:review_after => review_after,
                           :strength => strength_pre)

    # create rep
    Rep.create(:mem_id => self.id,
               :user_id => self.user_id,
               :confidence => confidence,
               :strength => strength_pre)

  end
  
end
