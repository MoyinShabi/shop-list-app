import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ionicons/ionicons.dart';
import 'package:shop_list_app/data/categories.dart';

import 'package:shop_list_app/models/shop_item.dart';
import 'package:shop_list_app/screens/new_item_screen.dart';

class ShopList extends StatefulWidget {
  const ShopList({super.key});

  @override
  State<ShopList> createState() => _ShopListState();
}

class _ShopListState extends State<ShopList> {
  List<ShopItem> _groceryItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final url = Uri.https(
        'shop-list-app-9e729-default-rtdb.firebaseio.com', 'shop-list.json');
    http.Response response;
    try {
      response = await http.get(url);
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again later.';
      });
      return;
    }
    if (response.statusCode >= 400) {
      setState(() {
        _error = 'Could not fetch data. Please try again later.';
      });
    }
    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final Map<String, dynamic> shopList = json.decode(response.body);
    final List<ShopItem> loadedItems = [];
    for (final item in shopList.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItems.add(
        ShopItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
  }

  Future<void> _addItem() async {
    final newItem = await Navigator.of(context).push<ShopItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) return;

    setState(() {
      _groceryItems.add(newItem);
    });
  }

  Future<void> _removeItem(ShopItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https('shop-list-app-9e729-default-rtdb.firebaseio.com',
        'shop-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Error deleting item!',
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.'),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.grey,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 18.0),
            child: const Icon(
              Ionicons.trash_outline,
              color: Colors.white,
              size: 21,
            ),
          ),
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
