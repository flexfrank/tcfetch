require "tokyocabinet"
require "uri"
module TCFetchCommon
  include TokyoCabinet
  CATALOGS=["may.2chan.net/b/"]
  TC_DIR="/var/tmp/"
  TC_PATH=File.join(TC_DIR,"tcfetch.db")

  def tdb_open(mode)
    tdb=TDB.new
    if(!tdb.open(TC_PATH,mode))
      ecode=tdb.ecode
      raise "open error #{tdb.errmsg(ecode)}"
    end
    begin
      return yield(tdb)
    ensure
      if !tdb.close
        ecode=tdb.ecode
        raise "close error #{tdb.errmsg(ecode)}"
      end
    end
  end


end
