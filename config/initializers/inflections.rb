# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format 
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

#
# 単数形/複数形の調整
#
ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'criterion', 'criteria'
  inflect.irregular 'database',  'databases'
end
