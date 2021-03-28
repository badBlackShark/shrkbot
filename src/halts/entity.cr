class Entity
  include JSON::Serializable

  property term : String
  property label : String
  property score : Float64
end
