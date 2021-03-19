# In tool selection

This demonstrates how a tool can include a selection stage if activated without
a usable selection. This is how native Move, Scale and Rotate behaves.

This approach can also be used for tools that only works on objects created
by the same extension. For instance a road plugin could have a tool for
adjusting the control points of your custom roads, and only be able to select
Groups representing such roads.

This example assumes you are already familiar with concepts from previous tool
examples.
