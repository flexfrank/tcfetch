require "tokyocabinet"
require "uri"
module TCFetchCommon
  include TokyoCabinet
  CATALOGS=[
    "may.2chan.net/b/",
    "img.2chan.net/b/",
    "jun.2chan.net/b/",
    "nov.2chan.net/b/",
    "dec.2chan.net/b/",
    "dat.2chan.net/b/",
    "may.2chan.net/27/",
    "dat.2chan.net/48/",
  ]
  TC_DIR="/var/tcfetch/"
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
