#include <iostream>
#include <string>
#include <vector>

using namespace std;


// Tokens reconocidos
struct Token
{
    string tipo;
    string lexema;
};


// Informacion de la instruccion
struct Instruccion
{
    string operacion;
    vector<string> registros;

    // -1 indica que no hay direccion
    int direccion = -1;
};


// Estados del AFD
enum class EstadoAFD
{
    INICIO,

    M,
    MO,
    MOV,

    A,
    AD,
    ADD,

    S,
    ST,
    STO,

    E,
    EN,
    END,

    ESPACIO,
    REGISTRO,
    REGISTRO_A,
    REGISTRO_B,
    REGISTRO_COMPLETO,

    NUMERO,

    ACEPTADO,
    ERROR
};


// Estados de la maquina de Moore
enum class EstadoMoore
{
    INICIO,

    MOV_MAR,
    MOV_MBR,
    MOV_REGISTRO,

    ADD,

    STO_MAR,
    STO_MBR,
    STO_MEMORIA,

    END,

    FIN
};


// Comprueba si el caracter es un digito
bool esDigito(char c)
{
    return c >= '0' && c <= '9';
}


// Validacion de la instruccion mediante el AFD
bool validarAFD(
    const string& entrada,
    vector<Token>& tokens,
    Instruccion& instruccion
)
{
    EstadoAFD estado = EstadoAFD::INICIO;

    string numero;

    size_t i = 0;

    while (i < entrada.length())
    {
        char caracter = entrada[i];

        switch (estado)
        {
            // Inicio
            case EstadoAFD::INICIO:

                if (caracter == 'M')
                {
                    estado = EstadoAFD::M;
                    i++;
                }
                else if (caracter == 'A')
                {
                    estado = EstadoAFD::A;
                    i++;
                }
                else if (caracter == 'S')
                {
                    estado = EstadoAFD::S;
                    i++;
                }
                else if (caracter == 'E')
                {
                    estado = EstadoAFD::E;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            // --------------------------------------------
            // MOV
            // --------------------------------------------

            case EstadoAFD::M:

                if (caracter == 'O')
                {
                    estado = EstadoAFD::MO;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            case EstadoAFD::MO:

                if (caracter == 'V')
                {
                    estado = EstadoAFD::MOV;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            case EstadoAFD::MOV:

                tokens.push_back({"MOV", "MOV"});
                instruccion.operacion = "MOV";

                estado = EstadoAFD::ESPACIO;

                break;


            // --------------------------------------------
            // ADD
            // --------------------------------------------

            case EstadoAFD::A:

                if (caracter == 'D')
                {
                    estado = EstadoAFD::AD;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            case EstadoAFD::AD:

                if (caracter == 'D')
                {
                    estado = EstadoAFD::ADD;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            case EstadoAFD::ADD:

                tokens.push_back({"ADD", "ADD"});
                instruccion.operacion = "ADD";

                estado = EstadoAFD::ESPACIO;

                break;


            // --------------------------------------------
            // STO
            // --------------------------------------------

            case EstadoAFD::S:

                if (caracter == 'T')
                {
                    estado = EstadoAFD::ST;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            case EstadoAFD::ST:

                if (caracter == 'O')
                {
                    estado = EstadoAFD::STO;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            case EstadoAFD::STO:

                tokens.push_back({"STO", "STO"});
                instruccion.operacion = "STO";

                estado = EstadoAFD::ESPACIO;

                break;


            // --------------------------------------------
            // END
            // --------------------------------------------

            case EstadoAFD::E:

                if (caracter == 'N')
                {
                    estado = EstadoAFD::EN;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            case EstadoAFD::EN:

                if (caracter == 'D')
                {
                    estado = EstadoAFD::END;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            case EstadoAFD::END:

                tokens.push_back({"END", "END"});
                instruccion.operacion = "END";

                // END no debe tener operandos
                if (i == entrada.length())
                {
                    estado = EstadoAFD::ACEPTADO;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            // --------------------------------------------
            // Espacios
            // --------------------------------------------

            case EstadoAFD::ESPACIO:

                if (caracter == ' ')
                {
                    // Se permiten uno o mas espacios
                    while (i < entrada.length() &&
                           entrada[i] == ' ')
                    {
                        i++;
                    }

                    if (instruccion.operacion == "MOV" ||
                        instruccion.operacion == "ADD")
                    {
                        estado = EstadoAFD::REGISTRO;
                    }
                    else if (instruccion.operacion == "STO")
                    {
                        estado = EstadoAFD::NUMERO;
                    }
                    else
                    {
                        estado = EstadoAFD::ERROR;
                    }
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            // --------------------------------------------
            // Registro
            // --------------------------------------------

            case EstadoAFD::REGISTRO:

                if (caracter == 'A')
                {
                    estado = EstadoAFD::REGISTRO_A;
                    i++;
                }
                else if (caracter == 'B')
                {
                    estado = EstadoAFD::REGISTRO_B;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            case EstadoAFD::REGISTRO_A:

                if (caracter == 'L')
                {
                    estado = EstadoAFD::REGISTRO_COMPLETO;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            case EstadoAFD::REGISTRO_B:

                if (caracter == 'L')
                {
                    estado = EstadoAFD::REGISTRO_COMPLETO;
                    i++;
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            // Registro completo
            case EstadoAFD::REGISTRO_COMPLETO:
            {
                string registro;

                if (entrada[i - 2] == 'A')
                {
                    registro = "AL";
                }
                else
                {
                    registro = "BL";
                }

                tokens.push_back({"REGISTRO", registro});
                instruccion.registros.push_back(registro);


                // ADD necesita otro registro
                if (instruccion.operacion == "ADD")
                {
                    while (i < entrada.length() &&
                           entrada[i] == ' ')
                    {
                        i++;
                    }

                    if (i < entrada.length() &&
                        entrada[i] == ',')
                    {
                        tokens.push_back({"COMA", ","});

                        i++;

                        while (i < entrada.length() &&
                               entrada[i] == ' ')
                        {
                            i++;
                        }

                        if (i < entrada.length())
                        {
                            estado = EstadoAFD::REGISTRO;
                        }
                        else
                        {
                            estado = EstadoAFD::ERROR;
                        }
                    }
                    else
                    {
                        estado = EstadoAFD::ERROR;
                    }
                }


                // MOV necesita una direccion
                else if (instruccion.operacion == "MOV")
                {
                    while (i < entrada.length() &&
                           entrada[i] == ' ')
                    {
                        i++;
                    }

                    if (i < entrada.length() &&
                        entrada[i] == ',')
                    {
                        tokens.push_back({"COMA", ","});

                        i++;

                        while (i < entrada.length() &&
                               entrada[i] == ' ')
                        {
                            i++;
                        }

                        if (i < entrada.length())
                        {
                            estado = EstadoAFD::NUMERO;
                        }
                        else
                        {
                            estado = EstadoAFD::ERROR;
                        }
                    }
                    else
                    {
                        estado = EstadoAFD::ERROR;
                    }
                }

                break;
            }


            // --------------------------------------------
            // Numero
            // --------------------------------------------

            case EstadoAFD::NUMERO:

                if (esDigito(caracter))
                {
                    numero.clear();

                    while (i < entrada.length() &&
                           esDigito(entrada[i]))
                    {
                        numero += entrada[i];
                        i++;
                    }

                    tokens.push_back({"NUMERO", numero});

                    instruccion.direccion = stoi(numero);


                    while (i < entrada.length() &&
                           entrada[i] == ' ')
                    {
                        i++;
                    }


                    if (i == entrada.length())
                    {
                        estado = EstadoAFD::ACEPTADO;
                    }
                    else
                    {
                        estado = EstadoAFD::ERROR;
                    }
                }
                else
                {
                    estado = EstadoAFD::ERROR;
                }

                break;


            // --------------------------------------------
            // Estados finales
            // --------------------------------------------

            case EstadoAFD::ACEPTADO:

                break;


            case EstadoAFD::ERROR:

                break;
        }


        if (estado == EstadoAFD::ERROR ||
            estado == EstadoAFD::ACEPTADO)
        {
            break;
        }
    }


    // ADD termina despues del segundo registro
    if (instruccion.operacion == "ADD" &&
        estado == EstadoAFD::REGISTRO_COMPLETO)
    {
        estado = EstadoAFD::ACEPTADO;
    }


    return estado == EstadoAFD::ACEPTADO;
}


// Genera las microoperaciones
void ejecutarMoore(const Instruccion& instruccion)
{
    EstadoMoore estado = EstadoMoore::INICIO;

    int paso = 1;


    while (estado != EstadoMoore::FIN)
    {
        switch (estado)
        {
            case EstadoMoore::INICIO:

                if (instruccion.operacion == "MOV")
                {
                    estado = EstadoMoore::MOV_MAR;
                }
                else if (instruccion.operacion == "ADD")
                {
                    estado = EstadoMoore::ADD;
                }
                else if (instruccion.operacion == "STO")
                {
                    estado = EstadoMoore::STO_MAR;
                }
                else if (instruccion.operacion == "END")
                {
                    estado = EstadoMoore::END;
                }

                break;


            // MOV
            case EstadoMoore::MOV_MAR:

                cout << paso++ << ". MAR <- "
                     << instruccion.direccion
                     << endl;

                estado = EstadoMoore::MOV_MBR;

                break;


            case EstadoMoore::MOV_MBR:

                cout << paso++ << ". MBR <- M[MAR]"
                     << endl;

                estado = EstadoMoore::MOV_REGISTRO;

                break;


            case EstadoMoore::MOV_REGISTRO:

                cout << paso++ << ". "
                     << instruccion.registros[0]
                     << " <- MBR"
                     << endl;

                estado = EstadoMoore::FIN;

                break;


            // ADD
            case EstadoMoore::ADD:

                cout << paso++ << ". ACC <- AL + BL"
                     << endl;

                estado = EstadoMoore::FIN;

                break;


            // STO
            case EstadoMoore::STO_MAR:

                cout << paso++ << ". MAR <- "
                     << instruccion.direccion
                     << endl;

                estado = EstadoMoore::STO_MBR;

                break;


            case EstadoMoore::STO_MBR:

                cout << paso++ << ". MBR <- ACC"
                     << endl;

                estado = EstadoMoore::STO_MEMORIA;

                break;


            case EstadoMoore::STO_MEMORIA:

                cout << paso++ << ". M[MAR] <- MBR"
                     << endl;

                estado = EstadoMoore::FIN;

                break;


            // END
            case EstadoMoore::END:

                cout << paso++ << ". HALT <- 1"
                     << endl;

                estado = EstadoMoore::FIN;

                break;


            case EstadoMoore::FIN:

                break;
        }
    }
}


// Muestra los tokens
void mostrarTokens(const vector<Token>& tokens)
{
    cout << "\nTOKENS RECONOCIDOS" << endl;

    for (const Token& token : tokens)
    {
        cout << token.tipo
             << "(\"" << token.lexema << "\")"
             << endl;
    }
}


// Muestra el objeto instruccion
void mostrarObjeto(const Instruccion& instruccion)
{
    cout << "\nOBJETO INSTRUCCION" << endl;

    cout << "{" << endl;

    cout << "    operacion: \""
         << instruccion.operacion
         << "\"" << endl;


    cout << "    registros: [";

    for (size_t i = 0;
         i < instruccion.registros.size();
         i++)
    {
        cout << "\""
             << instruccion.registros[i]
             << "\"";

        if (i + 1 < instruccion.registros.size())
        {
            cout << ", ";
        }
    }

    cout << "]" << endl;


    cout << "    direccion: ";

    if (instruccion.direccion == -1)
    {
        cout << "null";
    }
    else
    {
        cout << instruccion.direccion;
    }

    cout << endl;

    cout << "}" << endl;
}


// Programa principal
int main()
{
    string entrada;

    cout << "Ingrese una instruccion: ";
    getline(cin, entrada);


    cout << "\nVALIDACION MEDIANTE AFD" << endl;


    vector<Token> tokens;
    Instruccion instruccion;


    if (!validarAFD(entrada, tokens, instruccion))
    {
        cout << "Instruccion invalida." << endl;

        return 0;
    }


    cout << "Instruccion valida." << endl;


    mostrarTokens(tokens);


    cout << "\nCOMPONENTES IDENTIFICADOS" << endl;

    cout << "Mnemónico: "
         << instruccion.operacion
         << endl;


    if (!instruccion.registros.empty())
    {
        cout << "Registros: ";

        for (size_t i = 0;
             i < instruccion.registros.size();
             i++)
        {
            cout << instruccion.registros[i];

            if (i + 1 < instruccion.registros.size())
            {
                cout << ", ";
            }
        }

        cout << endl;
    }


    if (instruccion.direccion != -1)
    {
        cout << "Direccion de memoria: "
             << instruccion.direccion
             << endl;

        cout << "Direccionamiento: directo"
             << endl;
    }


    mostrarObjeto(instruccion);


    cout << "\nMICROOPERACIONES GENERADAS POR MOORE"
         << endl;

    ejecutarMoore(instruccion);


    cout << "Generacion terminada."
         << endl;


    return 0;
}
