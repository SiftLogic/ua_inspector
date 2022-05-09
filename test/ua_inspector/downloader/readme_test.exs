defmodule UAInspector.Downloader.READMETest do
  use ExUnit.Case, async: false

  alias UAInspector.Downloader.README

  @test_path Path.expand("../../downloads", __DIR__)
  @test_readme Path.join(@test_path, "ua_inspector.readme.md")

  setup_all do
    orig_path = Application.get_env(:ua_inspector, :database_path)
    remote_path = Application.get_env(:ua_inspector, :remote_path)
    skip_readme = Application.get_env(:ua_inspector, :skip_download_readme)

    :ok = Application.put_env(:ua_inspector, :database_path, @test_path)
    _ = File.rm_rf!(@test_path)

    on_exit(fn ->
      _ = File.rm_rf!(@test_path)
      :ok = Application.put_env(:ua_inspector, :database_path, orig_path)
      :ok = Application.put_env(:ua_inspector, :remote_path, remote_path)
      :ok = Application.put_env(:ua_inspector, :skip_download_readme, skip_readme)
    end)
  end

  test "README creation for default remote" do
    test_remote_path = [
      bot: "--ignore-value--",
      browser_engine: "--ignore-value--",
      client: "--ignore-value--",
      client_hints: "--ignore-value--",
      device: "--ignore-value--",
      os: "--ignore-value--",
      short_code_map: "--ignore-value--",
      vendor_fragment: "--ignore-value--"
    ]

    :ok = Application.put_env(:ua_inspector, :remote_path, test_remote_path)
    :ok = README.write()

    refute File.exists?(@test_readme)

    :ok = Application.delete_env(:ua_inspector, :remote_path)
    :ok = Application.put_env(:ua_inspector, :skip_download_readme, true)
    :ok = README.write()

    refute File.exists?(@test_readme)

    :ok = Application.delete_env(:ua_inspector, :skip_download_readme)
    :ok = README.write()

    assert File.exists?(@test_readme)
  end
end
