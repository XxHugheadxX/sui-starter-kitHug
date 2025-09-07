module starter::practica_sui {
    use std::debug::print;
    use std::string::{String, utf8};
    public struct Usuario has drop {
        vivo: bool,
        nombre: String,
        edad: u8,
    }
    fun practica(usuario: Usuario) {
      
        if(usuario.edad > 18) {
            print(&utf8(b"Eres mayor de edad"));
            print(&utf8(b"Eres mayor de edad"));
            print(&utf8(b"Eres mayor de edad"));

        }else if(usuario.edad == 18) {
            print(&utf8(b"Felicidades"));
        } else {
            print(&utf8(b"Eres menor de edad"));
        };
        if(usuario.vivo == true) {
            print(&utf8(b"Estas vivo"));
        } else {
            print(&utf8(b"Estas muerto"));
        }
        
      

    }

    #[test]
    fun prueba() {
        let usuario = Usuario {
           
            nombre: utf8(b"William"),
            edad: 18,
            vivo: true,
        };
        practica(usuario);
    }
}