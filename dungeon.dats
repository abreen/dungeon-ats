#include "share/atspre_staload.hats"

#define BOLD "\033[1m"
#define NO_BOLD "\033[22m"

#define HASH_TABLE_SIZE 256
#define DEFAULT_UNIVERSE_PATH "default.universe"

#define NORTH 0
#define EAST 1
#define SOUTH 2
#define WEST 3

staload "libats/ML/SATS/hashtblref.sats"
staload _ = "libats/DATS/hashfun.dats"
staload _ = "libats/DATS/linmap_list.dats"
staload _ = "libats/DATS/hashtbl_chain.dats"
staload _ = "libats/ML/DATS/hashtblref.dats"
staload UN = "prelude/SATS/unsafe.sats"


(*********************************************************
 * Exceptions
 *********************************************************)
exception BAD_SPAWN
exception EXIT_FROM_EMPTY
exception EXIT_TO_EMPTY
exception EXITS_OF_EMPTY
exception DESCRIBING_EMPTY


(*********************************************************
 * Data types
 *********************************************************)
datatype Direction = | North | East | South | West

fun direction_index(dir: Direction): natLt(4) =
  case+ dir of
  | North () => NORTH
  | East () => EAST
  | West () => WEST
  | South () => SOUTH

typedef Key = @{
  secret = int,
  description = string
}

datatype Space =
  | Room of (string,            // ID
             string,            // name
             string)            // description

  | Door of (string,            // ID
             string,            // name
             string,            // description
             Key)

  | Empty of ()

typedef Player = @{
  name = string,
  location = Space
}

typedef Item = @{
  name = string,
  description = string,
  location = Space
}


(*********************************************************
 * Printing representations of data structures
 *********************************************************)
fun print_dir (dir: Direction): void =
  case dir of
  | North () => print("north")
  | East () => print("east")
  | West () => print("west")
  | South () => print("south")

fun print_key (key: Key): void =
  let
    val () = print("Key('")
    val () = print(key.description)
    val () = print("', ")
    val () = print(tostring_val<int>(key.secret))
    val () = print(")")
  in () end

fun print_space_short (space: Space): void =
  case space of
  | Room (id, name, _) => (print(id); print(" "); print(name))
  | Door (id, name, _, _) => (print(id); print(" "); print(name))
  | Empty () => print("~")

fun print_space (space: Space): void =
  case space of
  | Room (id, name, desc) => (
      let
        val () = print($UN.cast{ptr}(space))
        val () = print(" Room('")
        val () = print(name)
        val () = print("', '")
        val () = print(desc)
        val () = print("'")
      in () end
    )
  | Door (id, name, desc, _) => (
      let
        val () = print("Door('")
        val () = print(name)
        val () = print("', '")
        val () = print(desc)
        val () = print("')")
      in () end
    )
  | Empty () => print("~")

fun print_player (player: Player): void =
  let
    val () = print("Player('")
    val () = print(player.name)
    val () = print("', ")
    val () = print_space(player.location)
    val () = print(")")
  in () end

fun print_item (item: Item): void =
  let
    val () = print("Item('")
    val () = print(item.name)
    val () = print("', '")
    val () = print(item.description)
    val () = print("', ")
    val () = print_space(item.location)
    val () = print(")")
  in () end

overload print with print_dir
overload print with print_key
overload print with print_space
overload print with print_player
overload print with print_item


(*********************************************************
 * Printing "descriptions" in the game
 *********************************************************)
symintr describe

fun describe_dir (dir: Direction): void =
  let
    val d: string = (
      case dir of
      | North () => "north"
      | East () => "east"
      | West () => "west"
      | South () => "south"
    )
    val () = print("to the ")
    val () = print_string(d)
  in () end

fun describe_key (key: Key): void = print_string(key.description)

fun describe_space (space: Space): void =
  case space of
  | Room (_, name, desc) => (
      print_string(BOLD);
      println!(name);
      print_string(NO_BOLD);
      print_string(desc);
      println!()
    )
  | Door (_, name, desc, _) => (
      print_string(BOLD);
      println!(name);
      print_string(NO_BOLD);
      print_string(desc);
      println!()
    )
  | Empty () => $raise DESCRIBING_EMPTY

fun describe_item (item: Item): void = print_string(item.description)

overload describe with describe_dir
overload describe with describe_key
overload describe with describe_space
overload describe with describe_item


(*********************************************************
 * Player & movement functions
 *********************************************************)
fun spawn_player (name: string, loc: Space): Player =
  case loc of
  | Empty() => $raise BAD_SPAWN
  | _ => @{name=name, location=loc}

fun exit_in_direction(exits: list(Space, 4), dir: Direction): bool =
  let
    val dest = exits[direction_index(dir)]
  in
    case dest of
    | Empty () => false
    | _ => true
  end

fun get_exit(exits: list(Space, 4), dir: Direction): Space =
  exits[direction_index(dir)]


(*********************************************************
 * Handling commands typed by the player
 *********************************************************)
datatype Command =
  | Move of (Direction)
  | Exits
  | Quit
  | Invalid of (string)

fun prompt (): [n: int | n > 0] string(n) =
  let
    fun loop (): [n: int | n > 0] string(n) =
      let
        val not_eof = fileref_isnot_eof(stdin_ref)
      in
        if not_eof then
          let
            val () = print("> ")
            val line = fileref_get_line_string(stdin_ref)
            val str = strptr2string(line)
            val len = string1_length(str)
          in
            if len <= 0 then loop()
            else str
          end
        else "quit"     // got EOF; return "quit"
      end
  in loop() end         // starting loop

fun get_command {n: int | n > 0} (cmd: string(n)): Command =
  let
    val first = cmd[0]
  in
    case first of
    | 'n' => Move(North)
    | 'e' => Move(East)
    | 's' => Move(South)
    | 'w' => Move(West)
    | 'x' => Exits
    | 'q' => Quit
    | _ => Invalid(cmd)
  end

fun print_exits(exits: list(Space, 4)): void =
  begin
    print("Ways out: ");
    (
      case exits[NORTH] of
      | Empty () => ()
      | _ => print("north ")
    );
    (
      case exits[EAST] of
      | Empty () => ()
      | _ => print("east ")
    );
    (
      case exits[SOUTH] of
      | Empty () => ()
      | _ => print("south ")
    );
    (
      case exits[WEST] of
      | Empty () => ()
      | _ => print("west")
    );
    println!()
  end


(*********************************************************
 * main() function
 *********************************************************)
implement main0 () =
let
  (*
   * Example: for a room with ID "rm1", to_north["rm1"] gives the
   * string ID of the space to the north of "rm1" (e.g., "rm2").
   *)
  val to_north =
    hashtbl_make_nil<string, string>(i2sz(HASH_TABLE_SIZE))
  val to_east =
    hashtbl_make_nil<string, string>(i2sz(HASH_TABLE_SIZE))
  val to_south =
    hashtbl_make_nil<string, string>(i2sz(HASH_TABLE_SIZE))
  val to_west =
    hashtbl_make_nil<string, string>(i2sz(HASH_TABLE_SIZE))

  val spaces =
    hashtbl_make_nil<string, Space>(i2sz(HASH_TABLE_SIZE))

  // for debugging
  fun print_hash_tables (): void =
    begin
      print("to_north: ");
      fprint_hashtbl(stdout_ref, to_north);
      print("\nto_east: ");
      fprint_hashtbl(stdout_ref, to_east);
      print("\nto_south: ");
      fprint_hashtbl(stdout_ref, to_south);
      print("\nto_west: ");
      fprint_hashtbl(stdout_ref, to_west);
      println!()
    end

  fun create_room (id: string, name: string, desc: string): Space =
    let
      val room = Room(id, name, desc)
      val _ = hashtbl_insert_any(spaces, id, room)
    in
      room
    end

  fun get_space_by_id (id: string): Space =
    let
      val result = hashtbl_search(spaces, id)
    in
      case result of
      | ~None_vt () => Empty()
      | ~Some_vt (sp) => sp
    end

  fun set_exit_id (from: Space, to_id: string, dir: Direction): void =
    let
      val from_id = (
        case from of
        | Room (id, _, _) => id
        | Door (id, _, _, _) => id
        | Empty () => ""
      )
      val table = (
        case dir of
        | North () => to_north
        | East () => to_east
        | South () => to_south
        | West () => to_west
      )
    in
      if eq_string_string(from_id, "") then
        $raise EXIT_FROM_EMPTY
      else if eq_string_string(to_id, "") then
        $raise EXIT_TO_EMPTY
      else
        hashtbl_insert_any(table, from_id, to_id)
    end

  fun set_exit (from: Space, to: Space, dir: Direction): void =
    let
      val to_id = (
        case to of
        | Room (id, _, _) => id
        | Door (id, _, _, _) => id
        | Empty () => ""
      )
    in
      set_exit_id(from, to_id, dir)
    end

  fun get_exits (space: Space): list(Space, 4) =
    let
      val id = (
        case space of
        | Room (room_id, _, _) => room_id
        | Door (door_id, _, _, _) => door_id
        | Empty () => ""
      )
      val north = case hashtbl_search(to_north, id) of
        | ~None_vt () => Empty()
        | ~Some_vt (dest_id) => get_space_by_id(dest_id)
      val east = case hashtbl_search(to_east, id) of
        | ~None_vt () => Empty()
        | ~Some_vt (dest_id) => get_space_by_id(dest_id)
      val south = case hashtbl_search(to_south, id) of
        | ~None_vt () => Empty()
        | ~Some_vt (dest_id) => get_space_by_id(dest_id)
      val west = case hashtbl_search(to_west, id) of
        | ~None_vt () => Empty()
        | ~Some_vt (dest_id) => get_space_by_id(dest_id)
    in
      if eq_string_string(id, "") then
        $raise EXITS_OF_EMPTY
      else
        cons(north, cons(east, cons(south, cons(west, nil()))))
    end

  fun open_universe (path: string): void =
    let
      val file: FILEref = fileref_open_exn(path, file_mode_r)
      fun read_space (): void =
        let
          val id = strptr2string(fileref_get_line_string(file))

          val north_exit = strptr2string(fileref_get_line_string(file))
          val east_exit = strptr2string(fileref_get_line_string(file))
          val south_exit = strptr2string(fileref_get_line_string(file))
          val west_exit = strptr2string(fileref_get_line_string(file))

          val name = strptr2string(fileref_get_line_string(file))
          val desc = strptr2string(fileref_get_line_string(file))

          val room = create_room(id, name, desc)
        in
          if eq_string_string(id, "") then ()
          else begin
            (
              case north_exit of
              | "~" => ()
              | exit_id => set_exit_id(room, exit_id, North)
            );
            (
              case east_exit of
              | "~" => ()
              | exit_id => set_exit_id(room, exit_id, East)
            );
            (
              case south_exit of
              | "~" => ()
              | exit_id => set_exit_id(room, exit_id, South)
            );
            (
              case west_exit of
              | "~" => ()
              | exit_id => set_exit_id(room, exit_id, West)
            );
            if fileref_isnot_eof(file) then
              read_space()      // read another one
            else ()
          end
        end

    in (read_space(); fileref_close(file))
    end

  val () = open_universe(DEFAULT_UNIVERSE_PATH)
  val spawn_space = get_space_by_id("spawn")

  var player: Player = spawn_player("You", spawn_space)

  val () = describe(player.location)

  fun loop (pl: &Player): void =
    let
      val here = pl.location
      val exits = get_exits(here)
      val line = prompt()
      val cmd = get_command(line)
    in
      case cmd of
      | Exits () => (print_exits(exits); loop(pl))
      | Move (dir) => (
          if exit_in_direction(exits, dir) then begin
            pl.location := get_exit(exits, dir);
            describe(pl.location);
            loop(pl);
          end else
            (println!("That is not a way out."); loop(pl))
        )
      | Invalid (str) => (
          print("Invalid command '");
          print(str);
          println!("'.");
          loop(pl)
        )
      | Quit () => println!("Bye!")
    end
in
  loop(player)
end
