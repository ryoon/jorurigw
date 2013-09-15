class DatetimeStr < ActiveRecord::Base
  gw_validates_datetime     :datetime_str,
                            :on => :create,
                            :message => 'fails with custom message',
                            :allow_nil => true
end
