module starter::biblioteca {
    use std::string::{String, utf8};
    use sui::vec_map::{VecMap, Self}; // almacenar libros nos sirve para simular base de datos interesante
// self te importa a ti mismo importa la libreria vec_map para poder llamar a las funciones

    #[error]
    const ID_YA_EXISTE: vector<u8> = b"El ID que intento agregar ya existe."; // codigo de error
    public struct Biblioteca has key { // key para que se pueda identificar de manera unica
        id: UID, //ES IMportante usar la key
        nombre: String,
        libros: VecMap<u64, Libro>, // id del libro y el libro
    }

    public struct Libro has copy, drop, store {
        titulo: String,
        autor: String,
        publicacion: u16,
        disponible: bool,

    }
    public fun crear_biblioteca(ctx: &mut TxContext){
        let biblioteca = Biblioteca {
            id:  object::new(ctx),
           nombre: utf8(b"Biblioteca Sui Latinoamerica"),
           libros: vec_map::empty(), // esto llegaria a ser un mapa vector vacio
        };
        transfer::transfer(biblioteca, tx_context::sender(ctx)); // puedes ahcer cosas que no se pueden editar nft librerias
    }
    public fun agregar_libro(biblioteca: &mut Biblioteca, id: u64, titulo: String, autor: String, publicacion: u16 ){
        assert!(!biblioteca.libros.contains(&id), ID_YA_EXISTE); // si el id ya existe no se puede agregar
            let libro = Libro { titulo, autor, publicacion, disponible: true }; //cuando se crea un libro esta disponible
            biblioteca.libros.insert(id, libro); // insertamos el libro en el mapa
    }
            

}
