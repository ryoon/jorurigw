module Gw::Admin::SchedulesHelper
  def weekday(w, mode='j')
    case mode
    when 'j'
      wa = [
        [0,'日'],
        [1,'月'],
        [2,'火'],
        [3,'水'],
        [4,'木'],
        [5,'金'],
        [6,'土'],
      ]
    when 'el'
      wa = [
        [0,'sunday'],
        [1,'monday'],
        [2,'tuesday'],
        [3,'wednesday'],
        [4,'thursday'],
        [5,'friday'],
        [6,'saturday'],
      ]
    end
    wa.assoc(w)[1]
  end
end
