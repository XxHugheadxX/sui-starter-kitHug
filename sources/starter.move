/// Definición del módulo
module donation_campaign::donation_campaign {

    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::event;
    use sui::balance::{Self, Balance};

    // --- Structs (Objetos) ---

    // El objeto de tesorería para el contrato. Solo existirá uno.
    public struct Treasury has key, store {
        id: UID,
        balance: Balance<SUI>,
        owner: address,
    }
    
    // Un objeto de campaña con la habilidad `key` para que pueda tener un ID único
    // y `store` para que pueda ser almacenado en otros objetos.
    public struct Campaign has key, store {
        id: UID,
        creator: address,
        title: vector<u8>,
        description: vector<u8>,
        goal: u64,
        raised: u64,
        donations: vector<DonationRecord>, // Un vector para almacenar las donaciones
        is_active: bool,
    }

    // Registro de una donación.
    public struct DonationRecord has store {
        donor: address,
        amount: u64,
    }

    // --- Eventos ---

    // Definimos los structs para los eventos, que deben tener las habilidades `copy` y `drop`.
    public struct CampanaCreada has copy, drop {
        campaign_id: ID,
        creator: address,
        goal: u64,
    }

    public struct DonacionRecibida has copy, drop {
        campaign_id: ID,
        donor: address,
        amount: u64,
    }

    public struct FondosRetirados has copy, drop {
        campaign_id: ID,
        creator: address,
        amount: u64,
    }

    // --- Funciones de Transacción (Entry functions) ---

    /// Función para inicializar el módulo. Se llama solo una vez.
    /// Crea el objeto Treasury que centralizará todos los fondos del contrato.
    fun init(ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        let treasury_object = Treasury {
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
            owner: sender,
        };

        // Transfiere la propiedad del objeto Treasury al creador.
        transfer::public_transfer(treasury_object, sender);
    }

    /// Crea una nueva campaña.
    entry fun crear_campana(
        title: vector<u8>,
        description: vector<u8>,
        goal: u64,
        ctx: &mut TxContext,
    ) {
        if (goal == 0) {
            abort 0
        };

        let sender = tx_context::sender(ctx);
        let campaign = Campaign {
            id: object::new(ctx),
            creator: sender,
            title,
            description,
            goal,
            raised: 0,
            donations: vector::empty(),
            is_active: true,
        };

        event::emit(CampanaCreada {
            campaign_id: object::id(&campaign),
            creator: sender,
            goal,
        });

        // Transfiere la propiedad del nuevo objeto 'Campaign' al creador
        transfer::public_transfer(campaign, sender);
    }

    /// Permite a un usuario donar a una campaña.
    public fun donar(
        campaign: &mut Campaign,
        treasury: &mut Treasury, // El objeto Treasury ahora se pasa como argumento
        donation_coin: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        if (!campaign.is_active) {
            abort 1
        };

        let sender = tx_context::sender(ctx);
        let amount = coin::value(&donation_coin);

        if (amount == 0) {
            abort 2
        };

        if (campaign.raised + amount > campaign.goal) {
            abort 3
        };

        // Se unen las monedas de la donación con el balance del tesoro.
        balance::join(&mut treasury.balance, coin::into_balance(donation_coin));

        // Actualiza el estado del objeto 'Campaign'
        campaign.raised = campaign.raised + amount;
        vector::push_back(&mut campaign.donations, DonationRecord { donor: sender, amount });

        // Emite un evento
        event::emit(DonacionRecibida {
            campaign_id: object::id(campaign),
            donor: sender,
            amount,
        });

        if (campaign.raised == campaign.goal) {
            campaign.is_active = false;
        };
    }

    /// Permite al dueño del Treasury retirar los fondos a su wallet.
    public fun retirar_fondos_de_tesoreria(
        treasury: &mut Treasury,
        amount: u64,
        recipient_address: address, // La dirección a la que se envían los fondos
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        if (sender != treasury.owner) {
            abort 4 // NotCreator
        };

        if (balance::value(&treasury.balance) < amount) {
            abort 5 // NoFundsToWithdraw
        };

        // Se extraen las monedas del Balance y se transfieren
        let withdrawn_coin = coin::take(&mut treasury.balance, amount, ctx);
        transfer::public_transfer(withdrawn_coin, recipient_address);

        event::emit(FondosRetirados {
            campaign_id: object::id(treasury),
            creator: sender,
            amount,
        });
    }

    /// Permite al creador retirar los fondos recaudados
    public fun retirar_fondos(
    campaign: &mut Campaign,
    treasury: &mut Treasury,
    ctx: &mut TxContext,
): Coin<SUI> {
    let sender = tx_context::sender(ctx);
    
    // Validamos que quien llama sea el creador de la campaña
    assert!(sender == campaign.creator, 4); // Código 4: NotCreator

    // Validamos que haya fondos disponibles para retirar
    assert!(campaign.raised > 0, 5); // Código 5: NoFundsToWithdraw

    let amount_to_withdraw = campaign.raised;

    // Extraemos las monedas del balance del treasury
    let withdrawn_coin = coin::take(&mut treasury.balance, amount_to_withdraw, ctx);

    // Actualizamos el estado de la campaña
    campaign.raised = 0;
    campaign.is_active = false;

    // Emitimos evento para registrar el retiro
    event::emit(FondosRetirados {
        campaign_id: object::id(campaign),
        creator: sender,
        amount: amount_to_withdraw,
    });

    // Retornamos las monedas sin transferirlas aquí para mantener la composabilidad
    withdrawn_coin
}

    // --- Funciones de vista (View functions) ---
    // En Sui, las funciones de vista se llaman fuera del contrato,
    // pero aquí está la lógica de cómo se accederían a los datos.
    public fun obtener_info_campana(campaign: &Campaign): (address, vector<u8>, u64, u64, bool) {
        (campaign.creator, campaign.title, campaign.goal, campaign.raised, campaign.is_active)
    }

    public fun obtener_monto_donacion(campaign: &Campaign, donor_address: address): u64 {
    // Obtenemos la referencia al vector de donaciones
    let donations = &campaign.donations;
    // Inicializamos la variable acumuladora en 0
    let mut amount = 0;
    // Inicializamos el índice para recorrer el vector
    let mut i = 0;
    // Obtenemos la longitud del vector de donaciones
    let len = vector::length(donations);
    // Recorremos todas las donaciones
    while (i < len) {
        // Tomamos la referencia al registro de donación en la posición i
        let record = vector::borrow(donations, i);
        // Si el donante coincide con la dirección que buscamos, sumamos el monto
        if (record.donor == donor_address) {
            amount = amount + record.amount;
        };
        i = i + 1;
    };

    // Retornamos el total acumulado de donaciones de ese donante
    amount
}
}
