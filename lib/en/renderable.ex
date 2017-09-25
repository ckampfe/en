defprotocol En.Renderable do
  @fallback_to_any true
  def render(term)
end

defimpl En.Renderable, for: Any do
  def render(term) do
    %{kind: "text", content: inspect(term) }
  end
end
