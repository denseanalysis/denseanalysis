# structobj
This is a class that simply wraps the functionality of the builtin `struct` datatype, but adds a number of useful features. The most notable feature, is that a `structobj` is a handle class and is therefore passed *by reference* to other functions. This allows you to essentially modify the structure *in-place*.

    S = structobj('Parameter1', 'value');
    addParameter(S);

    function addParameter(structure)
        % Simple function that adds a parameter without returned value
        structure.NewParameter = 'differentValue';
    end

Now when we display `S`, we see that it has been modified despite not being returned from the `addParameter` function.

    S =

        Parameter1: 'value'
        NewParameter: 'differentValue'

### Object Creation
You can create a `structobj` in a number of different ways

#### Standard Structure Inputs ####

The typical inputs can be passed to the `structobj` constructor

**Scalar Structure**

    S = structobj('a', 1, 'b', 2)

    S =

        a: 1
        b: 2

**Array of Structures**

    S = structobj('a', {1, 2}, 'b', {3, 4})

    S =

    1x2 struct array with fields:

        a
        b

**Dot Assignment**

    S = structobj();
    S.Program = 'structobj';

#### Existing struct

If you already have a structure (or array of structures) containing all of your data, you can simply pass that structure directly to the constructor.

    S = structobj(existingStructure);

Keep in mind that since the built-in `struct` datatype isn't passed by reference, any changes made to `S` *will not* be reflected in `existingStructure`.


### Additional Features

#### Events for data change

When the underlying data is changed, an event (`Updated`) is fired. You can register any callback to listen to this event using `addlistener`.

    S = structobj();

    listener = addlistener(S, 'Updated', @(s,e)disp('Updated!'))

    S.Name = 'Jonathan';

    Updated!

This is very useful if you use a `structobj` as a way to store data that underlies a GUI. This way, if any changes are made to the underlying data, you can have a listener that updates the necessary plots.


    S = structobj('x', [1,2,3], 'y', [1,2,3]);
    hplot = plot(S.x, S.y);
    listener = addlistener(S, 'Updated', @(s,e)set(hplot, 'XData', S.x, 'YData', S.y));



#### Conversion back to `struct`

If for some reason you need a *real* `struct` representation of your `structobj` object, you can cast it to a `struct`.

    realStruct = struct(S);

Again, remember that `realStruct` can no longer be passed by reference and any changes made to `realStruct` will not exist within `S`.

#### Update with another `struct` or `structobj`

If you want to add many fields to a `structobj` at once (whether they exist already or not), you can use the `update` method

    toUpdate = structobj('a', 1);
    updateWith = structobj('b', 2);

    update(toUpdate, updateWith)
    
    toUpdate = 
        
        a: 1
        b: 2

    update(toUpdate, struct('c', 3))

    toUpdate = 
        
        a: 1
        b: 2
        c: 3


#### Shallow copy of data

If you need a copy of the `structobj` that is *also* a `structobj` but *isn't* linked to the original data, you can create a shallow copy.

    S = structobj('a', 2);
    S2 = copy(S);

    disp(S2.a)

        2

    S2.a = 1;

    disp(S.a)
       
        2

    disp(S2.a)

        1


### Other Supported Functionality

* **Dynamic field references**

        fieldname = 'a';
        value = S.(fieldname);

* **Concatenation**

        S = [structobj('a', 1), structobj('a', 2)];
        S = [S; S]
        S = horzcat(S, S);
        S = vertcat(S, S);

* **Tab completion**

        S = structobj('parameter', 'value');
        >> S.<tab>

* **Field ordering**

        S = structobj('b', 1, 'a', 2);

        S = 

          b: 1
          a: 2

        orderfields(S)

        S = 

          a: 2
          b: 1

* **Field alteration methods**

        S = structobj();
        setfield(S, 'fieldname', 'value');
        tf = isfield(S, 'fieldname')
        value = getfield(S, 'fieldname');
        rmfield(S, 'fieldname');

* **Saving/Loading from file**

        S = structobj('field1', 'value1');
        save('data.mat', 'S');
        values = load('data.mat');

        values.S = 

            field1: 'value1'

### Testing

A suite of unit tests is distributed with this software and can be run using the following command

    results = structobj.test()

### Bug Reporting

Any issues or bugs should be reported to this project's [Github issue page][3]

### Attribution

Copyright (c) <2016> [Jonathan Suever][1].  
All rights reserved.

This software is licensed under the [three-clause BSD license][2].

[1]: https://github.com/suever
[2]: https://github.com/suever/structobj/blob/master/LICENSE
[3]: https://github.com/suever/structobj/issue
