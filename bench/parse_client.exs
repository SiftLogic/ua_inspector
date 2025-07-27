defmodule UAInspector.Benchmark.ParseClient do
  alias UAInspector.Parser.Client

  @agent_desktop "Mozilla/5.0 (AmigaOS; U; AmigaOS 1.3; en-US; rv:1.8.1.21) Gecko/20090303 SeaMonkey/1.1.15"
  @agent_hbbtv "Opera/9.80 (Linux mips ; U; HbbTV/1.1.1 (; Philips; ; ; ; ) CE-HTML/1.0 NETTV/3.2.1; en) Presto/2.6.33 Version/10.70"
  @agent_smartphone "Mozilla/5.0 (Linux; Android 6.0; U007 Pro Build/MRA58K; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/44.0.2403.119 Mobile Safari/537.36"
  @agent_tablet "Mozilla/5.0 (Linux; U; Android 4.2.2; it-it; Surfing TAB B 9.7 3G Build/JDQ39) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30"
  @agent_unknown "Mozilla/5.0 (Linux; U; Android 4.0.4; en-us; NABI2-NV7A Build/IMM76L)Maxthon AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Safari/534.30"

  def run do
    Benchee.run(
      %{
        "Parse Client: desktop" => fn -> Client.parse(@agent_desktop, %{}) end,
        "Parse Client: hbbtv" => fn -> Client.parse(@agent_hbbtv, %{}) end,
        "Parse Client: smartphone" => fn -> Client.parse(@agent_smartphone, %{}) end,
        "Parse Client: tablet" => fn -> Client.parse(@agent_tablet, %{}) end,
        "Parse Client: unknown" => fn -> Client.parse(@agent_unknown, %{}) end
      },
      formatters: [{Benchee.Formatters.Console, comparison: false}]
    )
  end
end

UAInspector.Benchmark.ParseClient.run()
