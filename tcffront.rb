require "rack"
require "uri"
require_relative "tcfcommon"
class TCFetchFront
  include TCFetchCommon
  def call(env)
    req=Rack::Request.new(env)
    base=req.params["base"]
    min=req.params["min"]
    deltas=req.params["deltas"] ? req.params["deltas"].split(",") : []
    if(base && min) 
      text=fetch(base,min,deltas)
    else
      text=""
    end
    res=Rack::Response.new([text])
    res["Content-Type"]="text/plain; charset=UTF-8"
    res.finish
  end

  def restore_uri(base_uri,min,delta)
    filename=(min.to_i+delta.to_i).to_s+".htm"
    URI.parse(base_uri)+filename
  end

  def restore_uris(base_uri,min,deltas)
    (["0"]+deltas).uniq.map do|delta|
      restore_uri(base_uri,min,delta)
    end
  end
  def fetch(base_uri,min,deltas)
    uris=restore_uris(base_uri,min,deltas)
    
    contents=nil
    tdb_open(TDB::OREADER) do|tdb|
      contents=uris.map do|uri|
        tdb[uri.to_s]
      end.compact
    end
    contents.map do|x|
      uri=x["uri"]
      content=x["content"].force_encoding("UTF-8").gsub(/\n|\r/," ")
      content=content.gsub(/\0/,'')
      content=content.encode("CP932",:undef=>:replace, :invalid=>:replace).encode("UTF-8")[0,20]
      content=" " if content.empty?
      [uri,content].join("\n")
    end.join("\n")

  end
end

if($0==__FILE__)
  #Rack::Handler::WEBrick.run(TCFetchFront.new,:Port => 8080)
  p TCFetchFront.new.fetch("http://img.2chan.net/b/res/","85269072",[])
end
