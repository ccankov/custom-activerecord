class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |method_name|
      define_method(method_name) do
        variable_name = "@#{method_name}".to_sym
        instance_variable_get(variable_name)
      end

      setter_name = "#{method_name}=".to_sym

      define_method(setter_name) do |value|
        variable_name = "@#{method_name}".to_sym
        instance_variable_set(variable_name, value)
      end
    end
  end
end
