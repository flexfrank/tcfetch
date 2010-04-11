require "tokyocabinet"
require "nokogiri"
require "open-uri"
require_relative "tcfcommon"
class TCFetch
  include TokyoCabinet
  include TCFetchCommon
  def initialize
    @catalogs=CATALOGS
    @sleep_duration=0.8
    @tc_dir=TC_DIR
    @tc_path=TC_PATH
  end

  def catalogs
    @catalogs.map{|cat| URI.parse("http://#{cat}futaba.php?mode=cat&sort=1")}
  end

  def fetch(cat_uri)
    cat_uri.open do|f|
      return f.read
    end
  end

  def thread_uris(catalog,catalog_uri)
    doc=Nokogiri::HTML.parse(catalog)
    base_uri=catalog_uri+"./"
    doc.css("td > a").map{|atag|atag.attr("href")}.
      select{|url|url =~ %r!res/\d+\.html?!}.
      map{|url| base_uri+url}
  end

  def fetch_content(thread_uri)
    doc=Nokogiri::HTML.parse(cp932!(thread_uri.read))
    doc.css("form > blockquote")[0].text
  end

  def cp932!(text)
    text.force_encoding("CP932")
  end


  def write_to_db(row)
    tdb_open(TDB::OWRITER|TDB::OCREAT) do|tdb|
      if !tdb.put(row["uri"],row)
        ecode=tdb.ecode
        raise "put error #{tdb.errmsg(ecode)}"
      end
    end
    
  end

  def fetch_and_write_thread_contents(threads)
    threads.each do|uri|
      r={"uri"=> uri.to_s,"content"=> fetch_content(uri), "time"=>Time.now.to_i.to_s}
      write_to_db(r) 

      sleep(@sleep_duration)
    end
    $stdout.puts("write #{threads.size}")
  end

  def filter_fetched(thread_uris)
    return thread_uris unless File.exist?(@tc_path)
    tdb_open(TDB::OREADER) do|tdb|
      thread_uris.select do|uri|
        !tdb.has_key?(uri.to_s)
      end
    end
  end

  def expire!
    return  unless File.exist?(@tc_path)
    yesterday=Time.now-24*60*60
    delete_keys=[]
    tdb_open(TDB::OREADER) do|tdb|
      query=TDBQRY.new(tdb)
      query.addcond("time", TDBQRY::QCNUMLT,yesterday.to_i.to_s)
      query.setlimit(100)
      delete_keys=query.search
    end
    tdb_open(TDB::OWRITER) do|tdb|
      delete_keys.each do|dk|
        tdb.out(dk)
      end
      $stdout.puts("expire #{delete_keys.size}")
      $stdout.puts("left #{tdb.size}")
    end
  end

  def run
    expire!
    catalogs.each do|cat|
      fetched=cp932!(fetch(cat))
      threads=thread_uris(fetched,cat)
      threads=filter_fetched(threads)
      fetch_and_write_thread_contents(threads)
    end
  end
end

TCFetch.new.run
