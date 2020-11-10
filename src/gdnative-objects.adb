with Interfaces.C.Strings;

with Ada.Tags;
with Ada.Exceptions;
with Ada.Unchecked_Conversion;
with Ada.Characters.Conversions;

with GDNative.Thin;
with GDNative.Context;
with GDNative.Console;
with GDNative.Exceptions;

package body GDNative.Objects is

  package S   renames System;
  package IC  renames Interfaces.C;
  package ICS renames Interfaces.C.Strings;
  package AE  renames Ada.Exceptions;
  package ACC renames Ada.Characters.Conversions;

  INVALID_REGISTRATION : constant Wide_String := "Calling default instance method implementation.";

  procedure Enter_Tree      (Self : in out Node)                          is begin Exceptions.Put_Warning (INVALID_REGISTRATION); end;
  procedure Exit_Tree       (Self : in out Node)                          is begin Exceptions.Put_Warning (INVALID_REGISTRATION); end;
  procedure Ready           (Self : in out Node)                          is begin Exceptions.Put_Warning (INVALID_REGISTRATION); end;
  procedure Process         (Self : in out Node; Delta_Time : in Real_64) is begin Exceptions.Put_Warning (INVALID_REGISTRATION); end;
  procedure Physics_Process (Self : in out Node; Delta_Time : in Real_64) is begin Exceptions.Put_Warning (INVALID_REGISTRATION); end;
 

  -------------------------
  -- Object Registration --
  -------------------------
  package body Object_Registration is

    type Access_New_Object is access New_Object;
    function Cast is new Ada.Unchecked_Conversion (S.Address, Access_New_Object);

    --------------
    -- Wrappers --
    --------------
    package Wrappers is
      function Create (
        p_instance    : System.Address;
        p_method_data : System.Address)
        return System.Address
        with Convention => C;
      procedure Destroy (
        p_instance    : System.Address;
        p_method_data : System.Address;
        p_user_data   : System.Address)
        with Convention => C;
    end;

    package body Wrappers is
      ------------
      -- Create --
      ------------
      function Create (
        p_instance    : S.Address;
        p_method_data : S.Address)
        return S.Address
      is
        Addr            : S.Address         := Context.Core_Api.godot_alloc (IC.int (New_Object'size));
        Access_Instance : Access_New_Object := Cast (Addr);
      begin
        Access_Instance.all := Initialize;
        return Addr;
      exception
        when Occurrence : others =>
          Exceptions.Put_Error (Occurrence);
          return S.Null_Address;
      end;
      -------------
      -- Destroy --
      -------------
      procedure Destroy (
        p_instance    : S.Address;
        p_method_data : S.Address;
        p_user_data   : S.Address)
      is begin
        Context.Core_Api.godot_free (p_user_data);
      exception
        when Occurrence : others => Exceptions.Put_Error (Occurrence);
      end;
    end;

    --------------------
    -- Register_Class --
    --------------------
    procedure Register_Class is
      Create_Func  : Thin.godot_instance_create_func  := (Wrappers.Create'access,  S.Null_Address, null);
      Destroy_Func : Thin.godot_instance_destroy_func := (Wrappers.Destroy'access, S.Null_Address, null);
     
      Name_Ptr      : ICS.chars_ptr := ICS.New_String (Ada.Tags.External_Tag (New_Object'Tag));
      Reference_Ptr : ICS.chars_ptr := ICS.New_String ("Reference");
    begin
      pragma Assert (Context.Core_Initialized,         CORE_UNINITIALIZED_ASSERT);
      pragma Assert (Context.Nativescript_Initialized, NATIVESCRIP_UNINITIALIZED_ASSERT);

      Console.Put ("Registering Class: " & ACC.To_Wide_String (Ada.Tags.External_Tag (New_Object'Tag)));

      Context.Nativescript_Api.godot_nativescript_register_class (
        Context.Nativescript_Ptr, 
        Name_Ptr,
        Reference_Ptr,
        Create_Func, 
        Destroy_Func);
      ICS.Free (Name_Ptr); 
      ICS.Free (Reference_Ptr);
    exception
      when Occurrence : others => Exceptions.Put_Error (Occurrence);
    end;

  end;

  --------------------------
  -- Wrap Instance Method --
  --------------------------
  function Wrap_Instance_Method (
    p_instance    : S.Address;
    p_method_data : S.Address;
    p_user_data   : S.Address;
    p_num_args    : IC.int;
    p_args        : Thin.Godot_Instance_Method_Args_Ptrs.Pointer) -- godot_variant **
    return Thin.godot_variant
  is
    Access_Instance : Access_Object := Cast (p_user_data);
    Parameters      : Parameters_State;
    Result          : Result_Type;
  begin
    Convert_Parameters (Parameters, p_args);
    Call_Callback (Access_Instance.all, Result, Parameters);
    return Convert_Result (Result);
  end;

  -----------------------
  -- Common Parameters --
  -----------------------
  type Void_Parameters is null record;
  subtype Real_64_Parameters is Real_64;

  procedure Convert_Void_Parameters (
    Parameters : in out Void_Parameters;
    p_args     : in     Thin.Godot_Instance_Method_Args_Ptrs.Pointer) is null;

  procedure Convert_Real_64_Parameters (
    Parameters : in out Real_64_Parameters;
    p_args     : in     Thin.Godot_Instance_Method_Args_Ptrs.Pointer) 
  is begin
    Parameters := Real_64 (Context.Core_Api.godot_variant_as_real (p_args.all));
  end;

  --------------------
  -- Common Results --
  --------------------
  type Void_Result is null record;

  function Convert_Void_Result (Result : in Void_Result) return Thin.godot_variant is (Context.Nil_Godot_Variant);

  -----------------------
  -- Node Registration --
  -----------------------
  package body Node_Registration is

    package Super_Registration is new Object_Registration (New_Node);
    procedure Register_Class renames Super_Registration.Register_Class;

    type Access_New_Node is access New_Node;
    function Cast is new Ada.Unchecked_Conversion (S.Address, Access_New_Node);

    procedure Call_Enter_Tree (
      Instance   : in out New_Node;
      Result     : in out Void_Result;
      Parameters : in     Void_Parameters)
    is begin
      Enter_Tree (Instance);
    exception
      when Occurrence : others => 
        Exceptions.Put_Error (Occurrence);
        AE.Reraise_Occurrence (Occurrence);
    end;

    procedure Call_Exit_Tree (
      Instance   : in out New_Node;
      Result     : in out Void_Result;
      Parameters : in     Void_Parameters)
    is begin
      Exit_Tree (Instance);
    exception
      when Occurrence : others => 
        Exceptions.Put_Error (Occurrence);
        AE.Reraise_Occurrence (Occurrence);
    end;

    procedure Call_Ready (
      Instance   : in out New_Node;
      Result     : in out Void_Result;
      Parameters : in     Void_Parameters)
    is begin
      Ready (Instance);
    exception
      when Occurrence : others => 
        Exceptions.Put_Error (Occurrence);
        AE.Reraise_Occurrence (Occurrence);
    end;

    procedure Call_Process (
      Instance   : in out New_Node;
      Result     : in out Void_Result;
      Parameters : in     Real_64_Parameters)
    is begin
      Process (Instance, Parameters);
    exception
      when Occurrence : others => 
        Exceptions.Put_Error (Occurrence);
        AE.Reraise_Occurrence (Occurrence);
    end;

    procedure Call_Physics_Process (
      Instance   : in out New_Node;
      Result     : in out Void_Result;
      Parameters : in     Real_64_Parameters)
    is begin
      Physics_Process (Instance, Parameters);
    exception
      when Occurrence : others => 
        Exceptions.Put_Error (Occurrence);
        AE.Reraise_Occurrence (Occurrence);
    end;

    function Enter_Tree_Wrapper is new Wrap_Instance_Method (
      New_Object         => New_Node,
      Access_Object      => Access_New_Node,
      Cast               => Cast, 
      Parameters_State   => Void_Parameters, 
      Result_Type        => Void_Result, 
      Convert_Parameters => Convert_Void_Parameters, 
      Call_Callback      => Call_Enter_Tree, 
      Convert_Result     => Convert_Void_Result);

    function Exit_Tree_Wrapper is new Wrap_Instance_Method (
      New_Object         => New_Node, 
      Access_Object      => Access_New_Node,
      Cast               => Cast, 
      Parameters_State   => Void_Parameters, 
      Result_Type        => Void_Result, 
      Convert_Parameters => Convert_Void_Parameters, 
      Call_Callback      => Call_Exit_Tree, 
      Convert_Result     => Convert_Void_Result);

    function Ready_Wrapper is new Wrap_Instance_Method (
      New_Object         => New_Node, 
      Access_Object      => Access_New_Node,
      Cast               => Cast, 
      Parameters_State   => Void_Parameters, 
      Result_Type        => Void_Result, 
      Convert_Parameters => Convert_Void_Parameters, 
      Call_Callback      => Call_Ready, 
      Convert_Result     => Convert_Void_Result);

    function Process_Wrapper is new Wrap_Instance_Method (
      New_Object         => New_Node, 
      Access_Object      => Access_New_Node,
      Cast               => Cast, 
      Parameters_State   => Real_64_Parameters, 
      Result_Type        => Void_Result, 
      Convert_Parameters => Convert_Real_64_Parameters, 
      Call_Callback      => Call_Process,
      Convert_Result     => Convert_Void_Result);

    function Physics_Process_Wrapper is new Wrap_Instance_Method (
      New_Object         => New_Node, 
      Access_Object      => Access_New_Node,
      Cast               => Cast, 
      Parameters_State   => Real_64_Parameters, 
      Result_Type        => Void_Result, 
      Convert_Parameters => Convert_Real_64_Parameters, 
      Call_Callback      => Call_Physics_Process, 
      Convert_Result     => Convert_Void_Result);

    procedure Register_Instance_Method is
      Instance_Method_Func : Thin.godot_instance_method   := (Instance_Method, S.Null_Address, null);
      Instance_Method_Attr : Thin.godot_method_attributes := (rpc_type => Thin.GODOT_METHOD_RPC_MODE_DISABLED);

      Name_Ptr        : ICS.chars_ptr := ICS.New_String (Ada.Tags.External_Tag (New_Node'tag));
      Method_Name_Ptr : ICS.chars_ptr := ICS.New_String (Method_Name);
    begin
      pragma Assert (Context.Core_Initialized,         CORE_UNINITIALIZED_ASSERT);
      pragma Assert (Context.Nativescript_Initialized, NATIVESCRIP_UNINITIALIZED_ASSERT);

      Console.Put (ACC.To_Wide_String ("Registering Method: " & Ada.Tags.External_Tag (New_Node'Tag) & "." & Method_Name));

      Context.Nativescript_Api.godot_nativescript_register_method (
        Context.Nativescript_Ptr,
        Name_Ptr,
        Method_Name_Ptr, 
        Instance_Method_Attr, 
        Instance_Method_Func);
      ICS.Free (Name_Ptr);
      ICS.Free (Method_Name_Ptr);
    exception
      when Occurrence : others => Exceptions.Put_Error (Occurrence);
    end;

    procedure Register_Enter_Tree_Impl      is new Register_Instance_Method ("_enter_tree",      Enter_Tree_Wrapper'access);
    procedure Register_Exit_Tree_Impl       is new Register_Instance_Method ("_exit_tree",       Exit_Tree_Wrapper'access);
    procedure Register_Ready_Impl           is new Register_Instance_Method ("_ready",           Ready_Wrapper'access);
    procedure Register_Process_Impl         is new Register_Instance_Method ("_process",         Process_Wrapper'access);
    procedure Register_Physics_Process_Impl is new Register_Instance_Method ("_physics_process", Physics_Process_Wrapper'access);
    
    procedure Register_Enter_Tree      renames Register_Enter_Tree_Impl;
    procedure Register_Exit_Tree       renames Register_Exit_Tree_Impl;
    procedure Register_Ready           renames Register_Ready_Impl;
    procedure Register_Process         renames Register_Process_Impl;
    procedure Register_Physics_Process renames Register_Physics_Process_Impl;
  end;
end;