defmodule Demeter.Parser do
  def parse(_data) do
    document = File.read!(File.cwd!() <> "/test/mocks/standard_xml.xml")

    handler = discover_handler()

    s = Saxy.parse_string(document, handler, [%{}])
    IO.inspect(s)
  end

  def discover_handler() do
    RSS2Standard
  end
end

defmodule RSS2Standard do
  @behaviour Saxy.Handler

  def handle_event(:start_document, _prolog, state) do
    {:ok, state}
  end

  def handle_event(:start_element, {tag_name, _attributes}, feeds) do
    IO.inspect(tag_name, label: "tag_name")
    IO.inspect(feeds, label: "feeds")

    if tag_name == "food" do
      feeds = [%{} | feeds]
      {:ok, {tag_name, feeds}}
    else
      {:ok, feeds}
    end
  end

  def handle_event(:characters, content, {current_tag, feeds}) do
    IO.inspect(current_tag, label: "current_tag")
    IO.inspect(feeds, label: "feeds")
    [current_feed | feeds] = feeds

    feed =
      case current_tag do
        "name" ->
          Map.put(current_feed, :name, content)

        "price" ->
          Map.put(current_feed, :price, content)

        "description" ->
          Map.put(current_feed, :description, content)

        _unsupported ->
          current_feed
      end

    {:ok, {"feed", [feed | feeds]}}
  end

  def handle_event(:end_document, _data, feed) do
    {:ok, feed}
  end
end
