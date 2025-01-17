import 'package:product_prices/generated/l10n.dart';
import 'package:product_prices/src/domain/domain.dart';
import 'package:product_prices/src/presentation/presentation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late final Products _productListState;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _productListState = context.read<Products>(); // Lee el estado de los productos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productListState.getProducts(); // Obtiene la lista de productos después de que se dibuje el widget.
    });
  }

  @override
  void dispose() {
    _productListState.dispose(); // Libera recursos al eliminar el estado.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).ourBestProducts),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            label: Text(
              S.of(context).watchCart,
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async => _productListState.getProducts(), // Permite refrescar la lista de productos.
            child: StreamBuilder<List<Product>>(
              stream: _productListState.productStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'), // Muestra error si hay uno.
                  );
                }

                if (!snapshot.hasData) {
                  // Muestra el esqueleto mientras los datos se están cargando.
                  return const ProductListSkeleton();
                }

                var productList = snapshot.data!;
                return _ProductListBody(
                  productList: productList,
                  onAddToCartAnimation: _triggerAnimation, // Callback para la animación de agregar al carrito.
                );
              },
            ),
          ),
          if (_isAnimating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.2),
                child: Center(
                  child: Lottie.asset(
                    'assets/lottie/add_to_cart_animation.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _triggerAnimation() {
    setState(() {
      _isAnimating = true; // Inicia la animación.
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isAnimating = false; // Detiene la animación después de 2 segundos.
      });
    });
  }
}

class _ProductListBody extends StatelessWidget {
  const _ProductListBody({
    required this.productList,
    required this.onAddToCartAnimation,
  });

  final List<Product> productList; // Lista de productos a mostrar.
  final VoidCallback onAddToCartAnimation; // Callback para manejar la animación de agregar al carrito.

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartNotifier>(); // Observa el estado del carrito.

    return ListView.separated(
      itemCount: productList.length,
      itemBuilder: (context, index) {
        final product = productList[index];

        return ProductItem(
          product: product,
          onAddToCartPressed: () {
            cart.addToCart(product); // Agrega el producto al carrito.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(S.of(context).addToCartSnackBar(product.title)),
                duration: const Duration(seconds: 1),
              ),
            );
            onAddToCartAnimation(); // Dispara la animación al agregar al carrito.
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(
        endIndent: 16.0,
        height: 1.0,
        indent: 16.0,
        thickness: 1.0,
      ),
    );
  }
}
