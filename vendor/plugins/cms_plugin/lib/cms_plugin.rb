class CmsPlugin
end

def load_fixture(file)
  str = IO.read(RAILS_ROOT + '/test/fixtures/' + file)
  return '"' + str.gsub('"', '""') + '"'
end
