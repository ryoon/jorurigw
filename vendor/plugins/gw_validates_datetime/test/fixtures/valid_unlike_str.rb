class ValidUnlikeStr < ActiveRecord::Base
  validates_unlike :str, :with =>/[a-z]/,
                   :message => "str can't include: [a-z]."
end
class NoHankanaStrBySelf < ActiveRecord::Base
  validates_unlike :str, :with =>/(?:\xEF\xBD[\xA1-\xBF]|\xEF\xBE[\x80-\x9F])/,
                   :message => "str can't include: hanKana."
end
class NoHankanaStr < ActiveRecord::Base
  validates_unlike_hankana :str, :message => "str can't include: hanKana."
end
