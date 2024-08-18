defmodule UAInspector.Util.Version do
  @moduledoc false

  @doc """
  Canonicalize a version for comparison.

  Matches canonicalization done by PHP's
  [version_compare](https://www.php.net/version_compare)
  to ensure matching upstream comparisons.

  ## Examples

      iex> canonicalize("1.0alpha")
      "1.0.alpha"

      iex> canonicalize("1.0alpha2")
      "1.0.alpha.2"

      iex> canonicalize("123.234+345")
      "123.234.345"

      iex> canonicalize("1...2")
      "1.2"

      iex> canonicalize("1.2-3+4.alpha5")
      "1.2.3.4.alpha.5"

      iex> canonicalize("1.02.03alpha")
      "1.2.3.alpha"

      iex> canonicalize("1.20304.alpha50607")
      "1.20304.alpha.50607"

      iex> canonicalize("1.020304.alpha050607")
      "1.20304.alpha.50607"

      iex> canonicalize("1.00.2")
      "1.0.2"

      iex> canonicalize("1.00alpha")
      "1.0.alpha"

      iex> canonicalize("1.02-03alpha04-05+00")
      "1.2.3.alpha.4.5.0"

      iex> canonicalize("1|2/3#4")
      "1.|.2./.3.#.4"

      iex> canonicalize("1p|c2")
      "1.p.|.c.2"

      iex> canonicalize("01.02")
      "1.2"

      iex> canonicalize("0001.02")
      "1.2"
  """
  @spec canonicalize(binary) :: binary
  def canonicalize(version) do
    version
    |> String.replace(~r/[-_+]/, ".")
    |> String.replace(~r/([^\d\.])([^\D\.])/, "\\1.\\2")
    |> String.replace(~r/([^\D\.])([^\d\.])/, "\\1.\\2")
    |> String.replace(~r/([[:alnum:]])([^[:alnum:]])/, "\\1.\\2")
    |> String.replace(~r/([^[:alnum:]])([[:alnum:]])/, "\\1.\\2")
    |> String.replace(~r/(?:^|\.)0+/, "0")
    |> String.replace(~r/(?:^|\.)0([\d]+)/, "\\1")
    |> String.replace(~r/\.\.+/, ".")
  end

  @doc """
  Compare two versions.

  ## Examples

      iex> compare("1.0.0", "1.0.1")
      :lt

      iex> compare("1.0.0", "1.0.0.4")
      :lt

      iex> compare("1.0.0.0", "1.0.0.1")
      :lt

      iex> compare("1.2.3", "1.02.03")
      :eq

      iex> compare("1.2.3", "1.020.3")
      :lt
  """
  @spec compare(binary, binary) :: :eq | :gt | :lt
  def compare(version1, version2) do
    semver1 = to_semver_with_pre(version1)
    semver2 = to_semver_with_pre(version2)

    Version.compare(semver1, semver2)
  end

  @doc """
  Compare two versions using canonicalized format.

  ## Examples

      iex> compare_canonicalized("1.2-3+4.alpha5", "1.2-3+4.alpha1")
      :gt

      iex> compare_canonicalized("1.02-03alpha04-05+00", "1.02-03alpha04-05+99")
      :lt

      iex> compare_canonicalized("1dev", "1alpha")
      :lt

      iex> compare_canonicalized("1alpha", "1beta")
      :lt

      iex> compare_canonicalized("1beta", "1rc")
      :lt

      iex> compare_canonicalized("1rc", "1")
      :lt

      iex> compare_canonicalized("1", "1patch")
      :lt

      iex> compare_canonicalized("1beta", "1patch")
      :lt

      iex> compare_canonicalized("1.02.03.04.05.06.alpha", "1.2.3.4.5.6alpha")
      :eq

      iex> compare_canonicalized("1", "1.0")
      :lt

      iex> compare_canonicalized("", "")
      :eq

      iex> compare_canonicalized("", "1")
      :lt

      iex> compare_canonicalized("1", "")
      :gt

      iex> compare_canonicalized(".", "1")
      :lt
  """
  @spec compare_canonicalized(binary, binary) :: :eq | :gt | :lt
  def compare_canonicalized(v1, v2) when is_binary(v1) and is_binary(v2) do
    c1 = v1 |> canonicalize() |> String.split(".")
    c2 = v2 |> canonicalize() |> String.split(".")

    do_compare_canonicalized(c1, c2)
  end

  @doc """
  Extract the major version from a version string.

  ## Examples

      iex> major("1.0.0")
      1

      iex> major("5.2")
      5

      iex> major("invalid")
      0

      iex> major("-1.2.3")
      0
  """
  @spec major(binary) :: non_neg_integer
  def major(version) do
    [major | _] =
      version
      |> canonicalize()
      |> String.split(".", parts: 2)

    case Integer.parse(major) do
      {value, _} when value > 0 -> value
      _ -> 0
    end
  end

  @doc """
  Sanitizes a version string.
  """
  @spec sanitize(version :: String.t()) :: String.t()
  def sanitize(""), do: ""

  def sanitize(version) do
    version
    |> String.replace(~r/\$(\d)/, "")
    |> String.replace(~r/\.$/, "")
    |> String.replace("_", ".")
    |> String.trim()
  end

  @doc """
  Converts an unknown version string to a semver-comparable format.

  Missing values are filled with zeroes while empty strings are ignored.

  If a non-integer value is found it is ignored and every part
  including and after it will be a zero.

  ## Examples

      iex> to_semver("15")
      "15.0.0"

      iex> to_semver("3.6")
      "3.6.0"

      iex> to_semver("8.8.8")
      "8.8.8"

      iex> to_semver("")
      ""

      iex> to_semver("invalid")
      "0.0.0"

      iex> to_semver("3.help")
      "3.0.0"

      iex> to_semver("0.1.invalid")
      "0.1.0"

      iex> to_semver("1.2.3.4")
      "1.2.3"

      iex> to_semver("1.2.3.4", 4)
      "1.2.3-4"

      iex> to_semver("-1.2.3.4")
      "0.0.0"

      iex> to_semver("1.-2.3.4")
      "1.0.0"

      iex> to_semver("1.2.-3.4")
      "1.2.0"

      iex> to_semver("1.2.3.-4")
      "1.2.3"
  """
  @spec to_semver(version :: String.t(), parts :: integer) :: String.t()
  def to_semver(version, parts \\ 3)
  def to_semver("", _), do: ""

  def to_semver(version, parts) do
    case String.split(version, ".", parts: parts) do
      [maj] -> to_semver_string(maj, "0", "0", nil)
      [maj, min] -> to_semver_string(maj, min, "0", nil)
      [maj, min, patch] -> to_semver_string(maj, min, patch, nil)
      [maj, min, patch, pre] -> to_semver_string(maj, min, patch, pre)
    end
  end

  defp comparison_priority("dev" <> _), do: 0
  defp comparison_priority("a" <> _), do: 1
  defp comparison_priority("b" <> _), do: 2
  defp comparison_priority("rc" <> _), do: 3
  defp comparison_priority(<<n::size(8), _::binary>>) when n in ~c'0123456789', do: 4
  defp comparison_priority("p" <> _), do: 5
  defp comparison_priority(_), do: -1

  defp do_compare_canonicalized([], []), do: :eq

  defp do_compare_canonicalized([], [v2 | _]) do
    if comparison_priority(v2) >= comparison_priority("0") do
      :lt
    else
      :gt
    end
  end

  defp do_compare_canonicalized([v1 | _], []) do
    if comparison_priority(v1) < comparison_priority("0") do
      :lt
    else
      :gt
    end
  end

  defp do_compare_canonicalized([<<p1::size(8), _::binary>> = v1 | c1], [
         <<p2::size(8), _::binary>> = v2 | c2
       ])
       when p1 in ~c'0123456789' and p2 in ~c'0123456789' do
    iv1 = String.to_integer(v1)
    iv2 = String.to_integer(v2)

    cond do
      iv1 < iv2 -> :lt
      iv1 > iv2 -> :gt
      iv1 == iv2 -> do_compare_canonicalized(c1, c2)
    end
  end

  defp do_compare_canonicalized([v1 | c1], [v2 | c2]) do
    p1 = comparison_priority(v1)
    p2 = comparison_priority(v2)

    cond do
      p1 < p2 -> :lt
      p1 > p2 -> :gt
      p1 == p2 -> do_compare_canonicalized(c1, c2)
    end
  end

  defp to_semver_string(major, minor, patch, pre) do
    version =
      case {Integer.parse(major), Integer.parse(minor), Integer.parse(patch)} do
        {:error, _, _} -> "0.0.0"
        {{maj, _}, _, _} when maj < 0 -> "0.0.0"
        {{maj, _}, :error, _} -> "#{maj}.0.0"
        {{maj, _}, {min, _}, _} when min < 0 -> "#{maj}.0.0"
        {{maj, _}, {min, _}, :error} -> "#{maj}.#{min}.0"
        {{maj, _}, {min, _}, {patch, _}} when patch < 0 -> "#{maj}.#{min}.0"
        {{maj, _}, {min, _}, {patch, _}} -> "#{maj}.#{min}.#{patch}"
      end

    if nil != pre do
      version <> "-" <> pre
    else
      version
    end
  end

  defp to_semver_with_pre(version) do
    semver = to_semver(version, 4)

    if String.contains?(semver, "-") do
      semver
    else
      semver <> "-0"
    end
  end
end
